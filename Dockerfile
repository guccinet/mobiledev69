FROM ghcr.io/cirruslabs/flutter:stable AS frontend-build

WORKDIR /workspace
COPY . .
RUN flutter pub get \
    && flutter build web --release --base-href=/static/app/

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_DEBUG=0

WORKDIR /app/backend
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./
COPY --from=frontend-build /workspace/build/web ./frontend_build/app
RUN DJANGO_SECRET_KEY=collectstatic-build-only python manage.py collectstatic --noinput

EXPOSE 10000
CMD ["sh", "-c", "gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-10000} --workers 2 --access-logfile -"]
