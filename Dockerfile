
FROM tomcat:9.0-jdk8-openjdk
# Copy MySQL driver
COPY mysql-connector-java-5.1.49.jar /usr/local/tomcat/lib/
COPY icu4j-4_4_2.jar /usr/local/tomcat/lib/

# Copy BIRT libs
# COPY birt-lib/*.jar /usr/local/tomcat/webapps/Web-CAT-Server/WEB-INF/lib/
# COPY birt-lib/*.jar /usr/local/tomcat/lib/

# Set environment
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH

# Deploy WAR
# COPY Web-CAT-Server.war $CATALINA_HOME/webapps/
COPY Web-CAT-Server2.war /usr/local/tomcat/webapps

# Optional: expose volume for Web-CAT data
VOLUME ["/usr/share/Web-CAT"]


# ------------------------------
# EXPOSE PORTS
# ------------------------------
EXPOSE 8080

