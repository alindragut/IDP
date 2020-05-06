import mysql.connector
import datetime
import uuid
from flask import Flask, render_template, request, session, redirect, url_for, jsonify, abort
from flask_socketio import SocketIO
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
app.config['SECRET_KEY'] = 'vnkdjnfjknfl1232#'
socketio = SocketIO(app)
mydb = mysql.connector.connect(
		host="db",
		user="root",
        	port="3306",
		password="root",
		database="IDP",
		auth_plugin='mysql_native_password',
		use_unicode=False
	)

cursor = mydb.cursor()

metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Application info', version = '1.0.3') 

@app.errorhandler(404)
def resource_not_found(e):
    return jsonify(error=str(e)), 404

@app.route('/',methods=['POST'])
def sessions():
	req = request.form

	uuid_ = req.get("uuid")
	course_id = req.get("course_id")
	channel_id = req.get("channel_id")

	user_id = []
	cursor.callproc('checkUuid', (str(uuid.UUID(uuid_)),))
	for i in cursor.stored_results():
		for j in i.fetchall():
			for k in j:
				user_id.append(k)

	if len(user_id) == 0:
		abort(404, description=str(uuid.UUID(uuid_)))

	session["user_id"] = user_id[0]

	course_count = []
	cursor.callproc('checkCourse', (session["user_id"], course_id, channel_id))
	for i in cursor.stored_results():
		for j in i.fetchall():
			for k in j:
				course_count.append(k)


	if len(course_count) == 0:
		session.pop("user_id")
		abort(404, description="course_count")

	session["channel_id"] = channel_id
	cursor.callproc('getName', (session["user_id"],))

	name = []
    	for i in cursor.stored_results():
		for j in i.fetchall():
			for k in j:
				name.append(k)

	if len(name) == 0:
		session.pop("user_id")
		session.pop("channel_id")
		abort(404, description="name")

	session["name"] = name[0]
	return render_template('index.html')

def messageReceived(methods=['GET', 'POST']):
	print('message was received!!!')

@socketio.on('my event')
def handle_my_custom_event(json, methods=['GET', 'POST']):
	if session.get("user_id") is None:
		return

	if json.get('message') is None:
		return

	cursor.callproc('postMessage', (session["user_id"],session["channel_id"],json["message"]))
    	mydb.commit()

	resp = {'date' : datetime.datetime.now().strftime("%m/%d/%Y at %H:%M"),
		'user_name' : session["name"],
		'message' : json['message']}

	socketio.emit('my response', resp, callback=messageReceived)

@socketio.on('get messages')
def handle_get_messages(json, methods=['GET', 'POST']):
	if session.get("user_id") is None:
		return

	d = {'date' : [], 'user_name' : [], 'message' : []}
	cursor.callproc("getMessages", (session["channel_id"],))
	for i in cursor.stored_results():
		for j in i.fetchall():
			d['date'].append(j[0].strftime("%m/%d/%Y at %H:%M"))
			d['user_name'].append(j[1])
			d['message'].append(j[2])
	socketio.emit('change messages', d, callback=messageReceived)

if __name__ == '__main__':
    socketio.run(app, host = '0.0.0.0', debug=True, port=5002)
