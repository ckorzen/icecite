include ../../Makefile

all: compile jar

compile:
	@mvn compile;

jar:
	@mvn assembly:single;

clean:
	@mvn clean;

run:
	@java -jar ./target/couchdb-log-parser.jar $(INPUT) $(OUTPUT)
	tail $(OUTPUT)
