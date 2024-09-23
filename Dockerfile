<<<<<<< HEAD

=======
################################################################
# Pull base image                                              #
################################################################
FROM python:3.12.6-alpine3.20

################################################################
# Set working directory                                        #
################################################################
WORKDIR /usr/src/app

################################################################
# Copy dependencies                                            #
################################################################
COPY requirements.txt .

################################################################
# Install dependencies                                         #
################################################################
RUN pip install --no-cache-dir -r requirements.txt

################################################################
# Copy all application                                         #
################################################################
COPY . .

################################################################
# Setup DB and Migrations                                      #
################################################################

# Set environment variables
ENV DJANGO_SUPERUSER_USERNAME=adeolu
ENV DJANGO_SUPERUSER_EMAIL=adeolu.ooa@gmail.com
ENV DJANGO_SUPERUSER_PASSWORD=Capstone1

RUN python manage.py makemigrations \
    && python manage.py migrate \
    && python manage.py createsuperuser --no-input

################################################################
# Alow argument -d to run container in background              #
################################################################
ARG d

################################################################
# Configure container port                                     #
################################################################
EXPOSE 80

################################################################
# Start up application                                         #
################################################################
CMD ["python", "manage.py", "runserver","0.0.0.0:80"]
>>>>>>> 1694368 (Added infra branch)
