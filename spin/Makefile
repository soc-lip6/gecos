#FILE=osa.pml
#FILE=tsi.pml
FILE=gecos.pml

all: pan
	./pan -m999999999

pan: pan.c
	gcc -DSAFETY pan.c -o pan	

pan.c: $(FILE)
	spin -a  $(FILE)

trail:
	spin -l -t -p $(FILE)

simul:
	spin -p -l $(FILE)

clean:
	rm -f pan* *trail
