FROM solr:9.8.1
COPY ./solr/gencon50-solr/ /opt/solr/configs/gencon50/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]
