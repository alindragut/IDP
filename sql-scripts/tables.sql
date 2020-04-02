create table courses (
	course_id int PRIMARY KEY AUTO_INCREMENT,
	course_name varchar(255) UNIQUE,
	course_owner int,
	price float,
	enrolled_students int,
	max_number_of_students int,
	duration datetime,
	channel_id int
);



create table channels (
	channel_id int PRIMARY KEY AUTO_INCREMENT,
	channel_name varchar(255)
);

create table users_enrolled_to_courses (
	user_id int,
	course_id int,
	PRIMARY KEY(user_id, course_id)
);

create table users (
	user_id int PRIMARY KEY AUTO_INCREMENT,
	username varchar(255) UNIQUE,
	password varchar(255),
	name varchar(255),
	is_student boolean
);

ALTER TABLE courses ADD FOREIGN KEY (course_owner) REFERENCES users (user_id);
ALTER TABLE courses ADD FOREIGN KEY (channel_id) REFERENCES channels (channel_id);
ALTER TABLE users_enrolled_to_courses ADD FOREIGN KEY (user_id) REFERENCES users (user_id);
ALTER TABLE users_enrolled_to_courses ADD FOREIGN KEY (course_id) REFERENCES courses (course_id);

insert into channels(channel_name) values ('test');
insert into users(username, password, name, is_student) values ('test', 'test_pw', 'test_name', 0);
insert into courses(course_name, course_owner, price, enrolled_students,
max_number_of_students, duration, channel_id) 
values ('test', 1, 3.99, 0, 20, '2020-08-08', 1);

