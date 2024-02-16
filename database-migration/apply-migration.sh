#!/bin/sh

for file in "$DIRECTORY"/*
do
  if [ -f "$file" ]; then
    case "$file" in
      *.sql)
        echo "Executing $file..."
        psql --host $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -p 5432 -f "$file"
    esac
  fi
done
