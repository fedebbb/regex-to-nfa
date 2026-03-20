Lisp


Rappresentare le regexs con delle liste formate cosi:

<re1><re2>..<rek>   diventa (c <re1> <re2> ... <rek>)

<re1> | <re2> | ... | <rek>  diventa (a <re1> <re2> ... <rek>)

<re>*  diventa (z <re>)

<re>+  diventa (o <re>)

L'alfabeto dei "simboli" sigma maiuscolo è costituito da S-exsps Lisp.


Funzioni richieste:


1. (is-regex RE) ritorna vero quando RE è un'espressione regolare; falso
(NIL) in caso contrario. Notate che un'espressione regolare può essere una
Sexsp nel qual caso il suo primo elemento deve essere diverso da c, o, z
oppure a.

2. (nfsa-compile-regex RE) ritorna l'automa ottenuto dalla compilazione di
RE, se è un'espressione regolare, altrimenti ritorna NIL. Attenzione, la
funzione non deve generare errori. Se non può compilare la regex RE, la
funzione semplicemente ritorna NIL.

3. (nfsa-recognize FA Input) ritorna vero quando l'input per l'automa FA
(ritornato da una precedente chiamata a nfsa-compile-regex) viene consumato
completamente e l'automa si trova in uno stato finale. Input è una lista Lisp
di simboli dell'alfabeto sigma maiuscolo sopra definito. Se FA non ha la
corretta struttura di un automa come ritornato da nfsa-compile-regex, la
funzione dovrà segnalare un errore. Altrimenti la funziona ritorna T se
riesce a riconoscere l'Input o NIL se non ce la fa.



Implementazione funzioni richieste:

1. (is-regex RE) questa funzione è stata implementata suddividendo i
vari casi:

- Caso atomo: la funzione ritorna T se la regex è un atom

- Caso lista in cui il primo elemento è riservato:

Sequenza e alternativa: se la lista ha 0 elementi oltre al primo riservato
la funzione ritorna T perchè è la rappresentazione del simbolo epsilon,
altrimenti se la lista ha almeno 2 elementi oltre al primo vengono verificati
se gli argomenti sono delle regex valide attraverso la funzione every e al
termine verrà ritornato T nel caso in cui è tutto valido altrimenti NIL.

(c) - Sequenza senza argomenti quindi sequenza di epsilon equivale al
simbolo epsilon

(a) - Alternativa senza argomenti quindi alternativa di epsilon equivale
al simbolo epsilon

Chiusura di Kleene e ripetizione: se la lista ha 0 elementi oltre al primo
riservato la funzione ritorna T perchè è la rappresentazione del simbolo
epsilon, altrimenti se la lista ha esattamente un elemento oltre al primo
viene verificato se è una regex valida chiamando is-regex su di esso e al
termine verrà ritornato T nel caso in cui è tutto valido altrimenti NIL.

(z) - Chiusura di Kleene senza argomenti quindi chiusura di Kleene di
epsilon equivale al simbolo epsilon

(o) - Ripetizione senza argomenti quindi ripetizione di epsilon equivale
al simbolo epsilon



- Caso lista in cui il primo elemento non è riservato:

la funzione ritorna T per qualsiasi lista con il primo elemento non riservato




2. (nfsa-compile-regex RE) chiamando questa funzione inizialmente si verifica
se la regex è valida chiamando is-regex sulla RE passata e nel caso in cui sia
vero allora viene chiamata (nfsa-create RE) altrimenti viene ritornato NIL.


Funzioni ausiliarie:

- (nfsa-create RE) questa funzione crea l'automa per la regex in base ai
seguenti casi:


- Caso atomo: nel caso in cui la regex è un atom vengono prima creati lo stato
iniziale e finale utilizzando la funzione gensym e successivamente viene
creata la struttura dell'automa con make-automa inserendo lo stato iniziale,
finale, la delta che è una lista con una sotto lista che contiene lo stato
iniziale, la RE, e lo stato finale e infine la epsilon_transition che in
questo caso è nil.


- Caso lista in cui il primo elemento è riservato:

Sequenza: in questo caso se non ci sono altri elementi oltre al primo
riservato viene creata la struttura dell'automa per il simbolo epsilon
con la funzione create_epsilon_automa. Altrimenti viene invocata
nfsa_create_args che crea ricorsivamente la struttura dell'automa per
ogni argomento mettendoli tutti in una lista Automi. Al termine viene
creata la struttura dell'automa sequenza con make-automa inserendo lo
stato iniziale del primo automa nella lista Automi, lo stato finale
dell'ultimo automa nella lista degli Automi, nella delta vengono aggiunte
le delta degli automi presenti nella lista Automi con la funzione get_delta
e infine nella epsilon transizione vengono aggiunte sia le epsilon
transizioni di ogni automa che vengono prese con get_epsilon_automi sia
le epsilon per la sequenza che vengono create con get_epsilon_conc.



Alternativa: in questo caso se non ci sono altri elementi oltre al primo
riservato viene creata la struttura dell'automa per il simbolo epsilon con
la funzione create_epsilon_automa. Altrimenti viene invocata nfsa_create_args
che crea ricorsivamente la struttura dell'automa per ogni argomento
mettendoli tutti in una lista Automi. Al termine vengono creati lo stato
iniziale e finale dell'alternativa con la funzione gensym e poi viene
creata la struttura dell'automa alternativa con make-automa inserendo lo
stato iniziale dell'alternativa, lo stato finale dell'alternativa, nella
delta vengono aggiunte le delta degli automi presenti nella lista Automi
con la funzione get_delta e infine nella epsilon transizione vengono aggiunte
sia le epsilon transizioni di ogni automa che vengono prese con
get_epsilon_automi sia le epsilon per l'alternativa che vengono create con
get_epsilon_alt.


Chiusura di Kleene: in questo caso se non ci sono altri elementi oltre al
primo riservato viene creata la struttura dell'automa per il simbolo epsilon
con la funzione create_epsilon_automa. Altrimenti viene invocata la
nfsa_create sull'elemento della lista oltre al primo per creare la struttura
del suo automa e viene salvato in A. Successivamente vengono creati lo stato
iniziale e finale della chisura di Kleene con la funzione gensym e infine
la struttura dell'automa della chiusura di Kleene con make-automa inserendo
lo stato iniziale della chiusura di Kleene, lo stato finale della chiusura di
Kleene, viene aggiunta la delta dell'automa dell'argomento della chiusura di
Kleene con automa-nfsa_delta e infine nella epsilon transizione vengono
aggiunte sia le epsilon transizioni dell'automa dell'argomento della chiusura
di Kleene con automa-nfsa_epsilon_transition sia le epsilon per la chiusura
di Kleene che vengono create con get_epsilon_Kleene.


Ripetizione: in questo caso se non ci sono altri elementi oltre al primo
riservato viene creata la struttura dell'automa per il simbolo epsilon con
la funzione create_epsilon_automa. Altrimenti viene invocata la nfsa_create
sull'elemento della lista oltre al primo per creare la struttura del suo
automa e viene salvato in A. Successivamente vengono creati lo stato iniziale
e finale della ripetizione con la funzione gensym e infine la struttura
dell'automa della ripetizione con make-automa inserendo lo stato iniziale
della ripetizione, lo stato finale della ripetizione, viene aggiunta
la delta dell'automa dell'argomento della ripetizione con automa-nfsa_delta
e infine nella epsilon transizione vengono aggiunte sia le epsilon
transizioni dell'automa dell'argomento della ripetizione con
automa-nfsa_epsilon_transition sia le epsilon per la ripetizione che vengono
create con get_epsilon_rip.



- Caso lista in cui il primo elemento non è riservato:


In questo caso vengono creati lo stato iniziale e finale con la funzione
gensym e successivamente viene creata la struttura dell'automa utilizzando
make-automa inserendo lo stato iniziale, lo stato finale, la delta che è una
lista con una sotto lista che contiene stato iniziale, la RE e stato finale
e infine viene inserita la epsilon transizione che in questo caso è nil.




- (create_epsilon_automa) questa funzione crea la struttura dell'automa per
il simbolo epsilon creando lo stato iniziale e finale con la funzione gensym
e successivamente la struttura dell'automa usando make-automa e inserendo
lo stato iniziale, lo stato finale, la delta a nil e la epsilon transizione
che è una lista con una sotto lista che contiene lo stato iniziale e lo
stato finale.



- (nfsa_create_args Args) crea ricorsivamente la struttura dell'automa per
ogni elemento della lista passata chiamando nfsa_create su ogni elemento





- La lista delle delta è stata creata utilizzando una lista che come
elementi contiene sottoliste e ogni sottolista rappresenta una delta
in modo tale da agevolare l'accesso ad esse per la funzione nfsa-recognize.

(get_delta Lista) crea una lista aggiungendo ricorsivamente le delta di ogni
elemento della lista passata.




- La lista delle epsilon transizioni è stata creata utilizzando una lista
che come elementi contiene sottoliste e ogni sottolista rappresenta
una epsilon transizione in modo tale da agevolare l'accesso ad esse per
la funzione nfsa-recognize.


(get_epsilon_conc Lista) La lista passata contiene gli automi degli argomenti
della sequenza. Questa funzione crea una lista aggiungendo ricorsivamente le
epsilon transizioni create per la sequenza. Viene creata la epsilon
transizione per gli elementi della lista a due a due creando la epsilon
transizione tra lo stato finale dell'automa corrente e lo stato iniziale
dell'automa successivo, viene richiamata ricorsivamente
get_epsilon_con fino a quando rimarrà un solo elemento nella Lista alla quale
non servirà la epsilon transizione perchè non ha elementi successivi.


(get_epsilon_alt Lista Start Final) crea una lista aggiungendo
ricorsivamente le epsilon transizioni create per l'alternativa. Per ogni
elemento della lista che contiene gli automi degli argomenti
dell'alternativa viene creata la epsilon transizione tra lo stato iniziale
dell'alternativa passato come parametro e lo stato iniziale dell'automa
corrente, successivamente viene creata la epsilon transizione tra lo stato
finale dell'automa corrente e lo stato finale dell'alternativa passato
come parametro. Infine viene richiamata ricorsivamente get_epsilon_alt
fino a quando la lista non sarà vuota.


(get_epsilon_kleene Element Start Final) crea una lista aggiungendo le
epsilon transizioni create per la chisura di Kleene. Nella lista vengono
aggiunte la epsilon transizione tra lo stato iniziale passato come parametro
e lo stato iniziale di Element che è l'automa dell'argomento della chiusura
di Kleene, la epsilon transizione tra lo stato finale di Element e lo stato
finale della chiusura di Kleene, la epsilon transizione tra lo stato iniziale
della chiusura di Kleene e lo stato finale della chiusura di Kleene e infine
la epsilon transizione che rappresenta il cappio ovvero tra lo stato finale
di Element e lo stato iniziale di Element.



(get_epsilon_rip Element Start Final) crea una lista aggiungendo le
epsilon transizioni create per la ripetizione. Nella lista vengono
aggiunte la epsilon transizione tra lo stato iniziale passato come
parametro e lo stato iniziale di Element che è l'automa dell'argomento
della ripetizione, la epsilon transizione tra lo stato finale di Element
e lo stato finale passato come parametro e infine la epsilon transizione
che rappresenta il cappio ovvero tra lo stato finale di Element e lo
stato iniziale di Element.



- (get_epsilon_automi Lista) In Lista ci sono gli automi degli argomenti
delle liste con il primo elemento riservato. Questa funzione crea una lista
aggiungendo tutte le epsilon transizioni degli automi presenti in Lista
rimuovendo i nil.



3. (nfsa-recognize FA Input) questa funzione verifica se FA ha la corretta
struttura di un automa altrimenti ritorna errore, verifica se Input è
una lista altrimenti ritorna NIL e infine verifica con accept se l'Input
passato viene consumato completamente da FA e si trova in uno stato finale.


Funzioni ausiliarie:


- (accept FA Input S) S indica gli stati sulla quale verrà applicata la
funzione eclose e al termine sarà salvato in States. Se Input è vuoto
verrà verificato se all'interno di States è presente lo stato finale e nel
caso sia vero sarà tornato T altrimenti NIL. Nel caso in cui Input non è
vuoto verrà chiamata state_transition che trova gli stati raggiungibili
da State consumando un simbolo di Input e al termine verranno salvati in
NextStates. Infine verrà chiamata la funzione accept con FA, il resto
dell'input e NextStates.



- (eclose FA S Visited) Questa funzione ritorna una lista che è l'eclose
(gli stati raggiungibili con epsilon transizioni) degli stati S. Inoltre
è presente Visited nella quale vengono salvati gli stati visitati in modo da
evitare cicli infiniti per l'eclose. Ad ogni chiamata si verifica se
l'elemento corrente di S è già presente nella lista Visited e nel caso sia
vero viene chiamata la funzione eclose con FA, il resto di S e Visited
perchè lo stato S è già stato visitato. Gli stati raggiungibili con epsilon
transizioni per ogni stato in S vengono trovati con la funzione
get_nextstate_epsilon e vengono salvati in NextEpsilonStates infine viene
chiamata ricorsivamente eclose con FA, il resto di S aggiungendo
NextEpsilonStates e il primo elemento di S aggiungendo la lista Visited. Il
tutto viene ripetuto fino a che la lista S è vuota e viene ritornata la
lista Visited.



- (state_transition FA Element States) questa funzione crea una lista
aggiungendo ricorsivamente gli stati raggiungibili da ogni elemento in States
consumando Element. Lo stato raggiungibile da uno stato in S consumando
Element trovato con get_nextstate viene salvato in NextState e nel caso
in cui NextState non sia nil viene aggiunto come lista alla lista che verrà
tornata al termine della ricorsione se invece è nil perchè non ci sono stati
raggiungibili da uno stato in S consumando Element non verrà aggiunto nulla,
verrà richiamata la funzione state_transition con FA, Element e il resto di
States. Il tutto viene ripetuto fino a che la lista States è vuota e verrà
ritornata la lista costruita.


- (get_nextstate_epsilon Lista State) Lista rappresenta le epsilon
transizioni dell'automa FA. Questa funzione ritorna una lista che contiene
gli stati raggiungibili con epsilon transizione da State. Si ripeterà il
tutto fino a che Lista non sarà vuota.



- (get_nextstate Lista Element State) Lista rappresenta le delta dell'automa
FA. Questa funzione ritorna lo stato raggiungibile da State consumando
Element. La ricerca è ricorsiva e si ripeterà fino a che non troverà una
delta oppure Lista è vuota.




Alcuni esempi:



- Simbolo epsilon

(is-regex '(c))
T

(is-regex '(z))
T

(is-regex '(a))
T

(is-regex '(o))
T



- Liste con primo elemento non riservato

(is-regex '(foo bar a (z 1 2)))
T



- Creazione automi con simbolo epsilon


(defparameter nfsa1 (nfsa-compile-regex '(a (a) 1)))
nfsa1


(nfsa-recognize nfsa1 '())
T

(nfsa-recognize nfsa1 '(1))
T

(nfsa-recognize nfsa1 '(()))
NIL


(defparameter nfsa2 (nfsa-compile-regex '(c (c) 1)))
nfsa2

(nfsa-recognize nfsa2 '(1))
T

(nfsa-recognize nfsa2 '())
NIL



- Creazione automi di liste con primo elemento non riservato

(defparameter nfsa3 (nfsa-compile-regex '(foo bar (z 1 2))))
nfsa3

(nfsa-recognize nfsa3 '((foo bar (z 1 2))))
T

(nfsa-recognize nfsa3 '(foo bar (z 1 2)))
NIL


