# Test stage
FROM alpine AS test
LABEL application=todobackend

# install basic utilities
RUN apk add --no-cache bash git

# install build dependencies
RUN apk add --no-cache gcc python3-dev libffi-dev musl-dev linux-headers py3-pip mariadb-dev
RUN pip install --upgrade pip
RUN pip install wheel

# copy requirements
COPY /src/requirements* /build/
WORKDIR /build

# build and install requirements
RUN pip wheel -r requirements_test.txt --no-cache-dir --no-input
RUN pip install -r requirements_test.txt -f /build --no-index --no-cache-dir

# copy source code
COPY /src /app
WORKDIR /app

# test entrypoint
CMD [ "python3", "manage.py", "test", "--noinput", "--settings=todobackend.settings_test" ]


# Release stage
FROM alpine
LABEL application=todobackend

# install operating system dependencies
RUN apk add --no-cache python3 py3-pip mariadb-client bash

# create app user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app

# copy and install application source and pre-built dependencies
COPY --from=test --chown=app:app /build /build
COPY --from=test --chown=app:app /app /app
RUN pip install -r /build/requirements.txt -f /build --no-index --no-cache-dir
RUN rm -rf /build

# Create public volume
RUN mkdir /public
RUN chown app:app /public
VOLUME /public

# set working directory and application user
WORKDIR /app
USER app
