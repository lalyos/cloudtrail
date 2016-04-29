## usage

Filter cloudtrail events from today:
```
./cloudtrail-today.sh ferenc.schneider
```

## skip s3 sync

S3 cynch of cloudtrail json file can be slow, ypu can skip it with the  `DRY_RUN` env var:

```
DRY_RUN=1 ./cloudtrail-today.sh ferenc.schneider
```

