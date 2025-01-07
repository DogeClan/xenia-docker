# Use Debian latest as the base image
FROM debian:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install necessary packages
RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    git \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    python3-venv \
    clang \
    llvm \
    libsdl2-dev \
    libglew-dev \
    libxcb1-dev \
    libx11-xcb-dev \
    libxcb-glx0-dev \
    libxcb-shm0-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxi-dev \
    libxxf86vm-dev \
    libgl1-mesa-dev \
    libgles2-mesa-dev \
    libvulkan-dev \
    libgtk-3-dev \
    libpthread-stubs0-dev \
    liblz4-dev \
    libx11-dev \
    libiberty-dev \
    libunwind-14-dev \
    libc++-dev \
    libc++abi-dev \
    x11vnc \
    xvfb \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment and install Flask and websockify
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install flask websockify

# Clone the Xenia repository
RUN git clone https://github.com/xenia-project/xenia.git /opt/xenia

# Initialize and update submodules
RUN cd /opt/xenia && git submodule update --init --recursive

# Set working directory to Xenia
WORKDIR /opt/xenia

# Setup and build Xenia
RUN ./xb setup \
    && ./xb build || (cat build/Debug/*.log && exit 1)

# Install noVNC
RUN git clone https://github.com/novnc/noVNC.git /opt/novnc \
    && cd /opt/novnc \
    && git checkout v1.3.0 \
    && ln -s vnc_lite.html index.html

# Set up the Flask app directory
WORKDIR /opt/flask_app

# Create the Flask app file and add the Python content
RUN echo 'from flask import Flask, request, redirect, url_for, flash, render_template' > /opt/flask_app/app.py \
    && echo 'import os' >> /opt/flask_app/app.py \
    && echo '' >> /opt/flask_app/app.py \
    && echo 'UPLOAD_FOLDER = "/opt/flask_app/uploads"' >> /opt/flask_app/app.py \
    && echo 'ALLOWED_EXTENSIONS = {"xex", "iso"}' >> /opt/flask_app/app.py \
    && echo '' >> /opt/flask_app/app.py \
    && echo 'app = Flask(__name__)' >> /opt/flask_app/app.py \
    && echo 'app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER' >> /opt/flask_app/app.py \
    && echo 'app.secret_key = "supersecretkey"' >> /opt/flask_app/app.py \
    && echo '' >> /opt/flask_app/app.py \
    && echo 'def allowed_file(filename):' >> /opt/flask_app/app.py \
    && echo '    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS' >> /opt/flask_app/app.py \
    && echo '' >> /opt/flask_app/app.py \
    && echo '@app.route("/")' >> /opt/flask_app/app.py \
    && echo 'def upload_form():' >> /opt/flask_app/app.py \
    && echo '    return render_template("upload.html")' >> /opt/flask_app/app.py \
    && echo '' >> /opt/flask_app/app.py \
    && echo '@app.route("/upload", methods=["POST"])' >> /opt/flask_app/app.py \
    && echo 'def upload_file():' >> /opt/flask_app/app.py \
    && echo '    if "file" not in request.files:' >> /opt/flask_app/app.py \
    && echo '        flash("No file part")' >> /opt/flask_app/app.py \
    && echo '        return redirect(request.url)' >> /opt/flask_app/app.py \
    && echo '    file = request.files["file"]' >> /opt/flask_app/app.py \
    && echo '    if file.filename == "":' >> /opt/flask_app/app.py \
    && echo '        flash("No selected file")' >> /opt/flask_app/app.py \
    && echo '        return redirect(request.url)' >> /opt/flask_app/app.py \
    && echo '    if file and allowed_file(file.filename):' >> /opt/flask_app/app.py \
    && echo '        filename = file.filename' >> /opt/flask_app/app.py \
    && echo '        file.save(os.path.join(app.config["UPLOAD_FOLDER"], filename))' >> /opt/flask_app/app.py \
    && echo '        flash("File successfully uploaded")' >> /opt/flask_app/app.py \
    && echo '        return redirect(url_for("upload_form"))' >> /opt/flask_app/app.py \
    && echo '    else:' >> /opt/flask_app/app.py \
    && echo '        flash("Allowed file types are xex, iso")' >> /opt/flask_app/app.py \
    && echo '        return redirect(request.url)' >> /opt/flask_app/app.py \
    && echo '' >> /opt/flask_app/app.py \
    && echo 'if __name__ == "__main__":' >> /opt/flask_app/app.py \
    && echo '    if not os.path.exists(UPLOAD_FOLDER):' >> /opt/flask_app/app.py \
    && echo '        os.makedirs(UPLOAD_FOLDER)' >> /opt/flask_app/app.py \
    && echo '    app.run(host="0.0.0.0", port=5000)' >> /opt/flask_app/app.py

# Create the templates directory and add the HTML content
RUN mkdir -p /opt/flask_app/templates \
    && echo '<!doctype html>' > /opt/flask_app/templates/upload.html \
    && echo '<html lang="en">' >> /opt/flask_app/templates/upload.html \
    && echo '<head>' >> /opt/flask_app/templates/upload.html \
    && echo '    <meta charset="UTF-8">' >> /opt/flask_app/templates/upload.html \
    && echo '    <meta name="viewport" content="width=device-width, initial-scale=1.0">' >> /opt/flask_app/templates/upload.html \
    && echo '    <title>Upload Game ROM</title>' >> /opt/flask_app/templates/upload.html \
    && echo '</head>' >> /opt/flask_app/templates/upload.html \
    && echo '<body>' >> /opt/flask_app/templates/upload.html \
    && echo '    <h1>Upload Game ROM</h1>' >> /opt/flask_app/templates/upload.html \
    && echo '    {% with messages = get_flashed_messages() %}' >> /opt/flask_app/templates/upload.html \
    && echo '        {% if messages %}' >> /opt/flask_app/templates/upload.html \
    && echo '            <ul>' >> /opt/flask_app/templates/upload.html \
    && echo '                {% for message in messages %}' >> /opt/flask_app/templates/upload.html \
    && echo '                    <li>{{ message }}</li>' >> /opt/flask_app/templates/upload.html \
    && echo '                {% endfor %}' >> /opt/flask_app/templates/upload.html \
    && echo '            </ul>' >> /opt/flask_app/templates/upload.html \
    && echo '        {% endif %}' >> /opt/flask_app/templates/upload.html \
    && echo '    {% endwith %}' >> /opt/flask_app/templates/upload.html \
    && echo '    <form method="post" enctype="multipart/form-data" action="{{ url_for("upload_file") }}">' >> /opt/flask_app/templates/upload.html \
    && echo '        <input type="file" name="file">' >> /opt/flask_app/templates/upload.html \
    && echo '        <input type="submit" value="Upload">' >> /opt/flask_app/templates/upload.html \
    && echo '    </form>' >> /opt/flask_app/templates/upload.html \
    && echo '</body>' >> /opt/flask_app/templates/upload.html \
    && echo '</html>' >> /opt/flask_app/templates/upload.html

# Create the supervisor config file for noVNC and Xvfb
RUN mkdir -p /etc/supervisor/conf.d/ \
    && echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf \
    && echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:xvfb]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=/usr/bin/Xvfb :99 -screen 0 1280x720x16' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'user=root' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/xvfb.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/xvfb_err.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:x11vnc]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=/usr/bin/x11vnc -display :99 -nopw -forever -shared' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'user=root' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/x11vnc.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/x11vnc_err.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo '[program:websockify]' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'command=websockify --web=/opt/novnc 6080 localhost:5900' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'user=root' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stdout_logfile=/var/log/websockify.log' >> /etc/supervisor/conf.d/supervisord.conf \
    && echo 'stderr_logfile=/var/log/websockify_err.log' >> /etc/supervisor/conf.d/supervisord.conf

# Expose the Flask and noVNC ports
EXPOSE 5000 6080

# Start supervisord to manage Xvfb, x11vnc, and websockify
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
