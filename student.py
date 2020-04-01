import mysql.connector
from flask import Flask, render_template, request, session, redirect, url_for, jsonify

app = Flask(__name__)
mydb = mysql.connector.connect(
		host="db",
		user="root",
        	port="3306",
		password="root",
		database="IDP"
	)

cursor = mydb.cursor()


@app.route('/')
@app.route('/index')
def index():
	return render_template('index.html')


@app.route('/courses')
def courses():
	l = []
	query = ("SELECT * from courses C inner join users_enrolled_to_courses E on "
		" E.course_id = C.course_id where E.user_id = 2")
	cursor.execute(query)
	for i in cursor:
		l.append(i)

	print(l)
	return render_template('courses.html', courses = l)

@app.route('/browse')
def browse():
	return render_template('index.html')

@app.route('/logout')
def logout():
	return render_template('index.html')

if __name__ == '__main__':
	app.run(host = '127.0.0.1', debug = True)
