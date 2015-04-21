#define NB_RD 1
#define NB_EL 4
#define NB_WR 1
#define ENDCH (NB_EL)
#define MAX_LOOP 4
#define MAX_ELEMS 255

typedef node
{
	byte key;
	byte next;
	byte mr_next;
	byte gc;
}

node mem[NB_EL]
#define get_node(i) mem[i]
#define get_next(i) mem[i].next
#define set_next(i,n) mem[i].next=n
#define get_mr_next(i) mem[i].mr_next
#define set_mr_next(i,n) mem[i].mr_next=n
#define get_gc(i) mem[i].gc
#define set_gc(i,n) mem[i].gc=n
#define get_key(i) mem[i].key
#define set_key(i,k) mem[i].key = k

byte list
byte freelist
#define free_node(a) \
	set_mr_next(a, freelist); \
	freelist = a

#define alloc_node(n) \
	n = freelist; \
	if \
	:: n < ENDCH -> freelist = get_mr_next(n) \
	:: else \
	fi

#if 0
#define sprandom(nr, max) \
	nr = 0;			\
	do			\
	:: nr < (max-1) -> nr++	\
	:: break		\
	od			
#else
#define sprandom(nr, max)	\
	if			\
	:: 1 -> nr=0		\
	:: 1 -> nr=1		\
	:: 1 -> nr=2		\
	:: 1 -> nr=3		\
	fi
#endif

bit tab[NB_EL]

bit max[NB_EL]//node that were inserted after the start
bit min[NB_EL]//node always in the list

proctype proc_search()
{
	byte cur;
	byte next;
	byte cgc;
	byte ngc;
	byte ckey;
	byte pkey;
	byte key;
	sprandom(key, NB_EL);

retry:
	//snapshot tab into min and max tabs
	atomic{
		int i;
		i=0;
		do
		:: i < NB_EL ->
			max[i] = tab[i];
			min[i] = tab[i];
			i++
		:: i >= NB_EL-> break
		od
	};

	pkey = 0;
	cur = list;
	if
	:: cur < ENDCH ->
		cgc = get_gc(cur);
		if
		:: (list != cur) -> goto retry
		:: else 
		fi
	:: else 
	fi;
	
	do
	:: cur < ENDCH -> 
		ckey = get_key(cur);
//relink:
		next = get_next(cur);
		if
		:: next < ENDCH -> ngc = get_gc(next);
		:: else 
		fi;
		if
		:: (get_next(cur) != next) -> goto retry//relink
		:: else 
		fi;
		if
		:: (get_gc(cur) != cgc) -> goto retry
		:: else 
		fi;

		if 
		::(ckey >= key) -> 
			atomic {
				if
				:: (ckey == key) -> //key found
					assert(max[key] == 1)
				:: else ->
					assert(min[key] == 0)
				fi
			};
			break	
		:: else -> 
			assert(ckey >= pkey);
			pkey = ckey;
			cgc = ngc;
			cur = next
		fi
	:: cur >= ENDCH -> break
	od;

}

proctype proc_write()
{
	byte i;
	byte loop;
	byte key;
	byte prev;

wloop:
	sprandom(key, NB_EL);

	if
	:: 1 ->
		//delete function
		prev = MAX_ELEMS;
		i = list;
		do
		:: i < ENDCH ->
			if 
			:: (get_key(i) >= key) ->
				if
				:: (get_key(i) == key) ->
					atomic {
						if
						:: (prev == MAX_ELEMS) -> list = get_next(i)
						:: else -> set_next(prev, get_next(i))
						fi;
						tab[get_key(i)] = 0;
						min[get_key(i)] = 0
					};
					get_gc(i)++;
					free_node(i);
					break
				:: else -> break
				fi;
				break
			:: else -> 
				prev = i;
				i = get_next(i)
			fi
		:: i >= ENDCH -> break
		od;
	:: 1 ->
		//insert function
		byte n;
		i = list;
		prev = MAX_ELEMS;
		do
		:: i < ENDCH ->
			if 
			:: (get_key(i) >= key) ->
				if
				:: (get_key(i) == key) -> goto out //key already exist	
				:: else -> break	
				fi;
			:: else -> 
				prev = i;
				i = get_next(i)
			fi
		:: i == ENDCH -> break //end of list reached
		:: i > ENDCH -> assert(0)
		od;

		//position located: insert the node
		alloc_node(n);
		if
		:: n == ENDCH -> assert(0)//; goto out
		:: else 
		fi;
		set_next(n, i);
		set_key(n, key);

		atomic {
			if
			:: (prev == MAX_ELEMS) -> list = n
			:: else -> set_next(prev, n)
			fi;
			tab[key] = 1;
			max[key] = 1
		}
	fi;
out:
	//loop again
	loop++;
	if
	:: loop < MAX_LOOP -> goto wloop
	:: else
	fi
}



init {
	// initialize liste content and freelist
	atomic {	
		int i = 0;
		list = ENDCH;
		assert(NB_EL < MAX_ELEMS);
		freelist = 0;
		do
		:: i < NB_EL ->
			mem[i].key = i;
			mem[i].next = ENDCH;
			mem[i].mr_next = i+1;
			mem[i].gc = 0;
			i++
		:: i >= NB_EL -> 
			mem[i-1].mr_next = ENDCH;
			break
		od
	};

	run proc_search();
	run proc_write();
}

