FROM python:2.7
COPY student.py /usr/src/app/
COPY requirements.txt /usr/src/app/
COPY templates_student/ /usr/src/app/templates/
RUN pip install -r /usr/src/app/requirements.txt
CMD [ "python", "./usr/src/app/student.py" ]
