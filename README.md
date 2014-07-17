vagrant-mdid
============

A vagrant box that sets up MDID is a method very similar to how we use it
in production.

## Use

1. Clone this repository and submodules
2. `vagrant up` (If you encounter any issues here, run `vagrant provision`
   to clean them up)
3. `vagrant ssh`
4. `cd /vagrant/rooibos`
5. `virtualenv venv`
6. `source venv/bin/activate`
7. `pip install -r requirements.txt`
8. `python rooibos/manage.py syncdb` (Answer yes and create new users as you go)
9. `python rooibos/manage.py migrate`
10. `pip install gunicorn` (This isn't in requirements.txt since you can pick
    from any WSGI server you like)
11. `gunicorn rooibos.wsgi:application -w 5 -t 180 --log-file - `
12. Things should be up and running, visit http://localhost:8080
