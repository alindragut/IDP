import mysql.connector
import datetime
import uuid
from flask import Flask, render_template, request, session, redirect, url_for, jsonify
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
app.config["SECRET_KEY"] = "89785cb474594c26920fb62b341a437b"
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

@app.before_request
def before_request():
    now = datetime.datetime.now()
    if not session.get('user_id') is None:
	    try:
		last_active = session['last_active']
		delta = now - last_active
		if delta.seconds > 300:
		    session['last_active'] = now
		    user_id = session["user_id"]
		    session.pop("user_id", None)
			
		    cursor.callproc('removeSessionForUser', (user_id,))
		    mydb.commit()
	    except:
		pass

	    try:
		session['last_active'] = now
	    except:
		pass

@app.route('/')
@app.route('/index')
def index():
	return render_template('index.html')

@app.route('/enroll', methods=["POST"])
def enroll():
	if session.get("user_id") is None:
		return redirect(url_for("login"))

	req = request.form

	course_id = req.get("course_id")

	cursor.callproc("enrollUserToCourse", (session["user_id"], course_id))
	mydb.commit()

	return redirect(url_for("browse"))

@app.route('/courses')
def courses():
	if session.get("user_id") is None:
		return redirect(url_for("login"))

	l = []
	cursor.callproc("getUserCourses", (session["user_id"], ))
	for i in cursor.stored_results():
		for j in i.fetchall():
			l.append(j)

	return render_template('courses.html', courses = l, uuid_ = str(session["uuid"]))

@app.route('/browse')
def browse():
	if session.get("user_id") is None:
		return redirect(url_for("login"))

	l = []
	cursor.callproc("getAllCourses", (session["user_id"], ))
	for i in cursor.stored_results():
		for j in i.fetchall():
			l.append(j)
	
	return render_template('browse.html', courses = l)

@app.route('/logout')
def logout():
	if session.get("user_id") is None:
		return redirect(url_for("login"))

	if not session.get('user_id') is None:
		user_id = session["user_id"]
		session.pop("user_id", None)
		session.pop("uuid", None)
		
		cursor.callproc('removeSessionForUser', (user_id,))
		mydb.commit()
		
	return render_template('index.html')

@app.route('/check', methods=["POST"])
def check():
	if not session.get("user_id") is None:
		return redirect(url_for("index"))
	
	req = request.form

	username = req.get("Username")
	password = req.get("Password")

	res = []

	cursor.callproc("checkUser", (username, password, True))

	for i in cursor.stored_results():
		for j in i.fetchall():
			for k in j:
				res.append(k)

	if len(res) == 0:
		return redirect(url_for("login"))

	session["user_id"] = res[0]
	session["uuid"] = uuid.uuid4()

	try:
		cursor.callproc('createSessionForUser', (str(session["uuid"]), session["user_id"]))
		mydb.commit()
	except:
		pass

	return redirect(url_for("courses"))

@app.route('/login')
def login():
	if not session.get("user_id") is None:
		session.pop("user_id", None)
		session.pop("uuid", None)

	return render_template('login.html')

@app.route('/create', methods=["POST"])
def create():
	if not session.get("user_id") is None:
		return redirect(url_for("index"))

	req = request.form

	username = req.get("Username")
	password = req.get("Password")
	name = req.get("Name")

	try:
		cursor.callproc('createUser', (username, password, name, True))
		mydb.commit()
	except:
		return redirect(url_for("register"))

	return render_template('success.html', name=name)

@app.route('/register')
def register():
	if not session.get("user_id") is None:
		session.pop("user_id", None)
		session.pop("uuid", None)

	return render_template('register.html')

if __name__ == '__main__':
	app.run(host = '0.0.0.0', debug = True)
