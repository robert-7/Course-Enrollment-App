import mongoengine
from flask import Flask
from flask_restx import Api
from flask_wtf.csrf import CSRFProtect

from config import get_config_for_env

# initiate the main web app
app = Flask(__name__)
app.config.from_object(get_config_for_env())

# enable CSRF protection for all POST forms
csrf = CSRFProtect(app)

# initiate the mongo engine
mongoengine.connect(
    db=app.config["MONGODB_SETTINGS"]["db"],
    host=app.config["MONGODB_SETTINGS"]["host"],
    uuidRepresentation="standard",
)

# initiate the API
api = Api(prefix="/api/v1", doc="/api/v1/docs")
api.init_app(app)

from application import routes  # noqa: E402,F401
