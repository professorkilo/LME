#!/usr/bin/env bash
source .env
USER=elastic
PASSWORD=${ELASTIC_PASSWORD_ESCAPED}
PROTO=https
REMOTE=10.20.0.174:9200

#TODO: make this a cli flag
#------------ edit this-----------
#assumes files are INDEX_mapping.json + INDEX.json
# mapping + logs
DIR=/data/logs/
INDICES=$(ls ${DIR} | cut -f -3 -d '.' | grep -v "_mapping"| grep -v "template"| sort | uniq)
#INDICES=$("elastalert_status" "elastalert_status_error" "elastalert_status_past" "elastalert_status_silence" "elastalert_status")


#------------ edit this -----------

echo -e "\n\ncheck \`podman logs -f CONTAINER_NAME\` for verbose output\n\n"
echo -e "\n--Uploading: --\n"
for x in ${INDICES};
do
  echo "podman runs for $x:"
  podman run  -it -d -v ${DIR}${x}_mapping.json:/tmp/data.json -e NODE_TLS_REJECT_UNAUTHORIZED=0 --userns="" --network=host  elasticdump/elasticsearch-dump   --output=/tmp/data.json   --input=${PROTO}://${USER}:${PASSWORD}@localhost:9200/${x}  --type=mapping

  podman run -v ${DIR}${x}:/tmp/ -e NODE_TLS_REJECT_UNAUTHORIZED=0 --userns="" --network=host --rm -ti elasticdump/elasticsearch-dump   --input=http://${REMOTE}/${x}   --output=/tmp/${x}.json --limit 5000
  echo ""
done

## cleanup: 
echo "--to cleanup when done:--"
echo "podman ps -a  --format \"{{.Image}} {{.Names}}\" | grep -i "elasticdump" | awk \'{print $2}\' | xargs podman rm"

tot=$(wc -l $(ls ${DIR} | grep -v "_mapping" | xargs -I{} echo ${DIR}{}))
echo -e "\n--Expected Log #:\n $tot--"
