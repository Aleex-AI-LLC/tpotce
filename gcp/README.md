# READ ME

## APPLY (user your own GCP auth json):

`sh tools/tf-apply.sh rank-mdr-terraform-key.json`

## DESTROY only the nodes (use your own GCP auth json):

`sh tools/tf-destroy-instances.sh rank-mdr-terraform-key.json`

## DESTROY everything (use your own GCP auth json):

`sh tools/tf-destroy.sh rank-mdr-terraform-key.json`

## REBOOT all honeys

`sh tools/tf-apply.sh rank-mdr-terraform-key.json`

## STATUS info

`sh tools/tf-status.sh rank-mdr-terraform-key.json`

## LIST nodes

`sh tools/tf-list.sh rank-mdr-terraform-key.json`

## SSH connect (mind of the ssh port):

```
gcloud compute ssh --zone "europe-west4-a" "hive" --project "rank-mdr" --ssh-flag="-p 64295"

sudo su - aleex
cd tpotce
```



## Sensor sanity checks

### check for no repeated errors:

`docker logs cowrie --tail 50`

### logstash events:

`docker logs logstash | tail -n 100`

### ensure elasticsearch indices exist and documents count:

```
docker exec -it elasticsearch curl http://localhost:9200/_cat/indices?v
docker exec -it elasticsearch curl http://localhost:9200/cowrie-*/_count
```

### docker internal networking

```
docker network ls
docker network inspect tpot
```

### quick check (run and wait):

```
watch -n 10 'docker exec elasticsearch curl -s http://localhost:9200/_cat/indices | grep -E "cowrie|dionaea|suricata"'
```


## Hive sanity checks

### hive is listening:

`ss -lntup`

### enable logstash debug:

```
docker exec -it logstash bash

logstash --log.level debug
```

## Certificate stuff

### Check whether certificate has the right IPs

```
openssl x509 -in certificate.crt -noout -text | grep -A1 "Subject Alternative Name"
```
