create database IDP;
use IDP;

create table courses (
	course_id int PRIMARY KEY AUTO_INCREMENT,
	course_name varchar(255) UNIQUE,
	course_owner int,
	max_number_of_students int,
	duration datetime,
	channel_id int
);



create table channels (
	channel_id int PRIMARY KEY AUTO_INCREMENT,
	channel_name varchar(255)
);

create table messages (
	channel_id int,
	user_id int,
	timestamp datetime,
	content varchar(255),
	PRIMARY KEY(user_id, channel_id, timestamp)
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

create table sessions (
	user_id int PRIMARY KEY,
	uuid binary(16) NOT NULL,
	timestamp datetime
);

ALTER TABLE courses ADD FOREIGN KEY (course_owner) REFERENCES users (user_id);
ALTER TABLE courses ADD FOREIGN KEY (channel_id) REFERENCES channels (channel_id);
ALTER TABLE users_enrolled_to_courses ADD FOREIGN KEY (user_id) REFERENCES users (user_id);
ALTER TABLE users_enrolled_to_courses ADD FOREIGN KEY (course_id) REFERENCES courses (course_id);
ALTER TABLE sessions ADD FOREIGN KEY (user_id) REFERENCES users (user_id);
ALTER TABLE messages ADD FOREIGN KEY (user_id) REFERENCES users (user_id);
ALTER TABLE messages ADD FOREIGN KEY (channel_id) REFERENCES channels (channel_id);

create trigger hashPassword BEFORE INSERT ON users
       FOR EACH ROW SET NEW.password = SHA2(NEW.password, 256);

insert into channels(channel_name) values ('test');
insert into channels(channel_name) values ('test2');
insert into channels(channel_name) values ('test3');
insert into users(username, password, name, is_student) values ('test', 'test_pw', 'test_name', 0);
insert into users(username, password, name, is_student) values ('test_student', 'test_pw', 'test_name_student', 1);
insert into courses(course_name, course_owner, 
max_number_of_students, duration, channel_id) 
values ('test', 1, 20, '2020-08-08', 1);
insert into courses(course_name, course_owner, 
max_number_of_students, duration, channel_id)
values ('test2', 1, 20, '2020-08-08', 2);
insert into courses(course_name, course_owner, 
max_number_of_students, duration, channel_id)
values ('test3', 1, 1, '2020-08-09', 3);
insert into users_enrolled_to_courses(user_id, course_id) values (2, 1);
insert into users_enrolled_to_courses(user_id, course_id) values (2, 2);

delimiter $$

create procedure getUserCourses(IN id int)
begin
	if (select U.is_student from users U where U.user_id = id) then
		select courses.course_name, users.name, courses.duration , courses.course_id, courses.channel_id
		from users_enrolled_to_courses 
		inner join courses on courses.course_id = users_enrolled_to_courses.course_id
		inner join users on courses.course_owner = users.user_id
		where users_enrolled_to_courses.user_id = id;
	else
		select courses.course_name, users.name, courses.duration, courses.course_id, courses.channel_id
		from courses
		inner join users on users.user_id = courses.course_owner
		where users.user_id = id;

	end if;
end $$



create procedure getAllCourses(IN id int)
begin
	select 	distinct C.course_name, 
		users.name, 
		C.duration, 
		IFNULL((select count(U1.course_id) 
			  from users_enrolled_to_courses U1
			  where U1.course_id = C.course_id
			  group by U1.course_id), 0) as 'curr_number_of_students', 
		C.max_number_of_students,
		IF(IFNULL((select count(U1.course_id) 
			  from users_enrolled_to_courses U1
			  where U1.course_id = C.course_id
			  group by U1.course_id), 0) = C.max_number_of_students
			or (select count(distinct CC.course_id)
				from courses CC
				inner join users_enrolled_to_courses UU on CC.course_id = UU.course_id
				where CC.course_id = C.course_id and UU.user_id = id) > 0,
			"NO",
			"YES") as 'eligible to enroll',
		C.course_id
	from users_enrolled_to_courses U
	right join courses C on C.course_id = U.course_id 
	inner join users on C.course_owner = users.user_id;
end $$

create procedure checkUuid(IN uuid_key varchar(255))
begin
	select user_id
	from sessions
	where BIN_TO_UUID(uuid) = uuid_key;
end $$

create procedure checkCourse(IN uid int, IN c_id int, IN ch_id int)
begin
	select count(U.course_id)
	from users_enrolled_to_courses U
	inner join courses C on U.course_id = C.course_id
	where U.user_id = uid and U.course_id = c_id and C.channel_id = ch_id;
end $$

create procedure createSessionForUser(IN uuid_key varchar(255), IN id int)
begin
	if (select user_id from sessions where user_id = id) then
		UPDATE sessions set uuid = UUID_TO_BIN(uuid_key), timestamp = NOW() where user_id = id;
	else
		INSERT INTO sessions (uuid, user_id, timestamp) values (UUID_TO_BIN(uuid_key), id, NOW());
	end if;
end $$

create procedure removeSessionForUser(IN id int)
begin
	DELETE FROM sessions WHERE user_id = id;
end $$

create procedure removeOldSessions()
begin
	DELETE FROM sessions WHERE TIME_TO_SEC(TIMEDIFF(NOW(), timestamp)) > 300;
end $$

create procedure enrollUserToCourse(IN id int, IN c_id int)
begin
	INSERT INTO users_enrolled_to_courses (user_id, course_id) values (id, c_id);
end $$

create procedure createCourse(IN c_owner int, IN c_name varchar(255), IN max_students int,
				IN end_date datetime, IN ch_name varchar(255))
begin
	declare ch_id int;
	INSERT INTO channels (channel_name) values (ch_name);
	set ch_id := LAST_INSERT_ID();
	INSERT INTO courses (course_name, course_owner, max_number_of_students, duration, channel_id)
	values (c_name, c_owner, max_students, end_date, ch_id);
end $$

create procedure createUser(IN uname varchar(255), IN pass varchar(255), IN real_name varchar(255), IN student boolean)
begin
	INSERT INTO users(username, password, name, is_student) values (uname, pass, real_name, student);
end $$

create procedure checkUser(IN uname varchar(255), IN pass varchar(255), IN student boolean)
begin
	select user_id, name from users where users.username = uname and users.password = SHA2(pass, 256) and users.is_student = student;
end $$

create procedure getMessages(IN chid int)
begin
	select M.timestamp, U.name, M.content
	from messages M
	inner join users U on M.user_id = U.user_id
	where M.channel_id = chid
	order by M.timestamp;
end $$

create procedure postMessage(IN uid int, IN chid int, IN msg varchar(255))
begin
	INSERT INTO messages(channel_id, user_id, timestamp, content) values (chid, uid, NOW(), msg);
end $$

create procedure getName(IN uid int)
begin
	select name from users where user_Id = uid;
end $$

delimiter ;
	



