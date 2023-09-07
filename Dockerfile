FROM rayproject/ray:2.6.3

ENV POETRY_VERSION=1.6.1

RUN pip install "poetry==$POETRY_VERSION"

WORKDIR /app
COPY ./poetry.lock ./pyproject.toml ./src/ray_demo/ .

# Project initialization:
RUN poetry install --no-dev --no-root --no-interaction --no-ansi

# copy and run program
COPY ./src/ray_demo/ .
CMD [ "poetry", "run", "python", "fib.py" ]
