FROM nvidia/cuda:12.0.0-base-ubuntu22.04
RUN mkdir /app
WORKDIR /app
COPY src /app/
# prevents Python from writing pyc files to disc
ENV PYTHONDONTWRITEBYTECODE 1
# # prevents Python from buffering stdout and stderr
ENV PYTHONUNBUFFERED 1
RUN apt update && apt-get install -y ffmpeg git python3-pip 
RUN pip install -r requirements.txt
RUN pip install "git+https://github.com/openai/whisper.git" 

CMD ["gunicorn", "-b", ":8080", "--reload", "main:app"]


