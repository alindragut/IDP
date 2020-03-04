FROM python:2.7
COPY student.py /usr/src/app/
COPY requirements.txt /usr/src/app/
COPY templates/base.html /usr/src/app/templates/
COPY templates/index.html /usr/src/app/templates/
COPY templates/courses.html /usr/src/app/templates/
RUN pip install -r /usr/src/app/requirements.txt
CMD [ "python", "./usr/src/app/student.py" ]
