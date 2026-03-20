Prolog


Le regexs possono essere rappresentate così:

- <re1><re2>...<rek>  diventa c(<re1>,<re2>,...,<rek>)
- <re1> | <re2> | <rek>  diventa a(<re1>,<re2>, ..., <rek>)
- <re>*  diventa z(<re>)
- <re>+  diventa o(<re>)

L'alfabeto dei simboli sigma maiuscolo è costituito da termini Prolog (più
precissamente, da tutto ciò che soddisfa compound/1 o atomic/1).


Predicati richiesti:


1. is_regex(RE) è vero quando RE è un'espressione regolare. Numeri e atomi
(in genere anche ciò che soddisfa atomic/1), sono le espressioni regolari
più semplici, i termini che soddisfano compound/1 non devono avere come
funtore uno dei funtori "riservati".


2. nfsa_compile_regex(FA_Id, RE) è vero quando RE è compilabile in un
automa, che viene inserito nella base dati del Prolog. FA_Id diventa un
identificatore per l'automa (deve essere un termine Prolog senza variabili
anche composto).


3. nfsa_recognize(FA_Id, Input) è vero quando l'input per l'automa
identificato da FA_Id, viene consumato completamente e l'automa si trova in
uno stato finale. Input è una lista Prolog di simboli dell'alfabeto sigma
maiuscolo sopra definito.


4. nfsa_delete_all, nfsa_delete(FA_Id) sono veri quando dalla base di dati
Prolog sono rimossi tutti gli automi definiti (caso nfsa_delete_all/0) o
l'automa FA_Id (caso nfsa_delete/1).



Implementazione dei predicati richiesti:

1. is_regex/1.

is_regex(RE).


è il predicato che abbiamo usato per il debugging e per controllare che la
regex in input sia una regex valida. Il predicato è stato implementato come
richiesto quindi la regex non è valida se contiene variabili libere oppure
se non soddisfa altre condizioni che verranno spiegate. La regex è valida
se soddisfa uno dei seguenti casi:


- Atomo: il caso in cui la regex è un atomo quindi soddisfa atomic/1.

- Termini composti con funtore riservato con numero argomenti diverso da 0:


Sequenza e alternativa: La regex viene controllata trasformando il termine
composto in una lista utilizzando =.. . Da questa lista vengono presi gli
argomenti del termine composto che devono essere almeno 2, altrimenti
non è valido, se è valido vengono passati al predicato ausiliario
regex_list/1 che ricorsivamente verifica che ogni elemento della lista
argomenti del funtore sia una regex valida.

Chiusura di Kleene e ripetizione: La regex viene controllata chiamando
is_regex/1 sull'argomento verificando che l'argomento della chiusura di
Kleene o ripetizione sia una regex valida e che ci sia un solo argomento.



- Termini composti con funtore non riservato e numero argomenti diverso da 0:

Compound: il caso in cui la regex è un termine che soddisfa compound/1 ma
il suo funtore è diverso dai funtori riservati e gli argomenti del termine
composto non sono variabili libere. Il termine composto viene controllato
trasformandolo in una lista utilizzando =.. . Da questa lista vengono presi
gli argomenti del termine composto e vengono passati al predicato ausiliario
regex_list_comp/1 che ricorsivamente verifica che ogni elemento della lista
argomenti del funtore non siano variabili libere. In questo modo all'interno
del termine composto è tutto ammesso (anche termini composti senza
argomenti) tranne le variabili libere.



- Termini composti con funtore riservato ma con 0 argomenti:


Questi casi sono stati implementati per poter rappresentare il simbolo
epsilon quindi saranno valide le regex con funtore riservato e 0 argomenti.
Per poter fare ciò è stato utilizzato functor/4 che permette di gestire i
termini composti senza argomenti.


c() - Sequenza senza argomenti quindi sequenza di epsilon equivale al
simbolo epsilon

a() - Alternativa senza argomenti quindi alternativa di epsilon equivale
al simbolo epsilon

z() - Chiusura di Kleene senza argomenti quindi chiusura di Kleene di
epsilon equivale al simbolo epsilon

o() - Ripetizione senza argomenti quindi ripetizione di epsilon equivale
al simbolo epsilon.


- Termini composti con funtore non riservato e 0 argomenti:


Il caso in cui la regex è un termine composto che soddisfa compound/1 ma
il suo funtore è diverso dai funtori riservati e ha 0 argomenti. Anche in
questo caso è stato gestito utilizzando functor/4 che permette di gestire
i termini composti con 0 argomenti.



Predicati ausiliari:

- regex_list/1.

regex_list(Lista). Lista rappresenta gli argomenti del termine composto con
funtore riservato.

Verifica ricorsivamente che ogni elemento della lista passata sia una
regex valida.




- regex_list_comp/1.

regex_list_comp(Lista). Lista rappresenta gli argomenti del termine
composto con funtore non riservato.


Verifica ricorsivamente che ogni elemento della lista passata non sia
una variabile libera. Se uno degli elementi soddisfa compound/1 allora
verranno verificati anche gli argomenti al suo interno sempre con
regex_list_comp/1.






2. nfsa_compile_regex/2.

nfsa_compile_regex(FA_Id, RE).

è il predicato che crea l'automa aggiungendo dinamicamente i fatti per lo
stato iniziale, finale, la delta e epsilon transizioni. L'automa viene
creato solo se la regex passata soddisfa is_regex/1, e che il nome
dell'automa non contiene variabili libere. Nel caso in cui esiste già un
automa con lo stesso FA_Id questo verrà eliminato con nfsa_delete/1 e poi
creato quello nuovo, se invece non esiste viene creato direttamente. Una
volta verificato che tutto sia valido viene chiamato il predicato
nfsa_create/5 per creare l'automa e infine vengono aggiunti dinamicamente
i fatti nfsa_init/2 che contiene FA_Id, stato iniziale e nfsa_final/2
che contiene FA_Id e stato finale.




Fatti dinamici utilizzati:

nfsa_init/2: che contiene identificatore automa e stato iniziale.

nfsa_final/2: che contiene identificatore automa e stato finale.

nfsa_delta/4: che contiene identificatore automa, stato di partenza,
simbolo e stato di arrivo.

nfsa_epsilon_transition/3: che contiene identificatore automa, stato
di partenza e stato di arrivo.


Per le epsilon transizioni abbiamo creato un fatto distinto rispetto alle
delta perchè non hanno il simbolo da consumare per effettuare la
transizione dello stato e per agevolarne l'accesso nella nfsa_recognize/2.






Predicati ausiliari:



- nfsa_create/5.

nfsa_create(FA_Id, RE, Delta, Start, Final).

crea l'automa in base alla regex:



- Caso Atomo: se la regex è un atomo allora viene creato l'automa creando
lo stato iniziale e lo stato finale con gensym/2 e viene aggiunto
dinamicamente il fatto nfsa_delta/4 con FA_Id, stato iniziale creato con
gensym/2, la regex e stato finale creato con gensym/2.


- Caso termini composti con funtore riservato e 0 argomenti:

Viene creato l'automa per il simbolo epsilon aggiungendo dinamicamente il
fatto nfsa_epsilon_transition/3 che contiene FA_Id, stato iniziale creato
con gensym/2 e stato finale creato con gensym/2.


- Caso termini composti con funtore non riservato e 0 argomenti:

Viene creato l'automa aggiungendo dinamicamente il fatto nfsa_delta/4 che
contiene FA_Id, stato iniziale creato con gensym/2, il termine composto
e stato finale creato con gensym/2.



- Caso termini composti con funtore riservato e numero argomenti diverso
da 0:


nfsa_create_concat/4.

nfsa_create_concat(FA_Id, Lista, Start, Final). Lista rappresenta gli
argomenti della sequenza.


Sequenza: Dalla nfsa_create/5 per il caso della sequenza viene chiamato
il predicato nfsa_create_concat/4 che ricorsivamente crea l'automa per
ogni argomento chiamando nfsa_create/5 su ogni elemento e una volta creati
gli automi due a due viene aggiunto dinamicamente il fatto
nfsa_epsilon_transition/3 che contiene FA_Id, stato finale del primo
automa e stato iniziale del secondo automa. Il caso base della ricorsione
è quando rimane un solo elemento in modo tale da poter creare l'automa su
quell'elemento e aggiungere dinamicamente il fatto nfsa_epsilon_transition/3
con FA_Id, stato finale dell'automa precedente e il suo stato iniziale.


nfsa_create_alt/4.

nfsa_create_alt(FA_Id, Lista, Start, Final). Lista rappresenta gli argomenti
dell'alternativa.


Alternativa: Vengono creati lo stato iniziale e finale con gensym/2 nella
nfsa_create/5 per il caso dell'alternativa e poi i due stati creati vengono
passati al predicato nfsa_create_alt/4 che ricorsivamente crea l'automa per
ogni argomento e una volta creato l'automa vengono aggiunti dinamicamente
il fatto nfsa_epsilon_transition/3 che contiene FA_Id, lo stato iniziale
passato a nfsa_create_alt/4 e lo stato iniziale dell'automa, poi il fatto
nfsa_epsilon_transition/3 che contiene FA_Id, lo stato finale dell'automa
e lo stato finale passato a nfsa_create_alt/4. Infine chiama ricorsivamente
il predicato fino alla lista vuota che è il caso base.



Chiusura di Kleene: Nel caso della chiusura di Kleene della nfsa_create/5
vengono creati lo stato iniziale e finale con gensym/2 poi viene chiamato
il predicato nfsa_create/5 per creare l'automa dell'argomento della
chiusura di Kleene e infine vengono aggiunti dinamicamente il fatto
nfsa_epsilon_transition/3 che contiene FA_Id, lo stato iniziale della
chiusura di Kleene e lo stato finale della chiusura di Kleene, il fatto
nfsa_epsilon_transition/3 che contiene FA_Id, lo stato iniziale della
chiusura di Kleene e lo stato iniziale dell'automa, il fatto
nfsa_epsilon_transition/3 che contiene FA_Id, lo stato finale dell'automa
e lo stato finale della chiusura di Kleene e infine il cappio ovvero
nfsa_epsilon_transition/3 che contiene FA_id, lo stato finale dell'automa
e lo stato iniziale dell'automa.



Ripetizione: Nel caso della ripetizione della nfsa_create/5 vengono creati
lo stato iniziale e finale con gensym/2 poi viene chiamato il predicato
nfsa_create/5 per creare l'automa dell'argomento ripetizione e infine
vengono aggiunti dinamicamente il fatto nfsa_epsilon_transition/3 che
contiene FA_Id, lo stato iniziale della ripetizione e lo stato iniziale
dell'automa, il fatto nfsa_epsilon_transition/3 che contiene FA_Id, lo
stato finale dell'automa e lo stato finale della ripetizione e infine
il cappio nfsa_epsilon_transition/3 che contiene FA_Id, lo stato finale
dell'automa e lo stato iniziale dell'automa.



- Caso termine composto con funtore non riservato e numero di argomenti
diverso da 0:


Se la regex è un termine che soddisfa compound/1 e il funtore è diverso
da quelli riservati e il numero di argomenti è diverso da 0, l'automa viene
creato creando lo stato iniziale e lo stato finale utilizzando gensym/2
e viene aggiunto dinamicamente il fatto nfsa_delta/4 che contiene FA_Id,
lo stato iniziale, la regex e lo stato finale.




- checking nfsa_id/1.

checking_nfsa_id(FA_Id).


è il predicato che verifica che il nome dell'automa non abbia variabili
libere e nel caso sia un termine composto vengono verificati anche gli
argomenti chiamando il predicato checking_args/1.



-checking_args/1.

checking_args(Lista). Lista rappresenta gli argomenti di un termine composto
presente nel nome dell'automa.

Verifica ricorsivamente che gli elementi della lista passata non siano
variabili libere e che nel caso in cui gli elementi della lista
siano termini composti al loro interno non ci siano variabili libere.









3. nfsa_recognize/2


nfsa_recognize(FA_Id, Input).


nfsa_recognize è il predicato che permette di verificare se una stringa in
input viene riconosciuta da un determinato automa contraddistinto
dall'identificatore univoco FA_Id, inizia recuperando lo stato iniziale
dell'automa tramite nfsa_init/2 e inizia a riconoscere la stringa in input
chiamando accept/4.



Predicati ausiliari:

- accept/4.

accept(FA_Id, Input, State, Visited). La lista Visited rappresenta gli stati
con epsilon transizioni già visitati in modo tale da evitare cicli infiniti
per le epsilon transizioni. Nel caso in cui venga consumato un simbolo
la lista Visited viene svuotata perchè così si potrà effettuare il cappio
ad esempio nella chiusura di Kleene o ripetizione.


Il caso base di accept/4 è la stringa in input vuota e verifica se ci
troviamo in uno stato finale grazie a nfsa_final/2, le altre due clausole
di accept/4 rappresentano rispettivamente il consumo di un carattere
della stringa in input cercando una transizione utilizzando nfsa_delta/4
con argomento FA_Id, lo stato attuale e la Head della stringa in input
successivamente viene richiamata ricorsivamente accept/4 sulla Tail della
stringa con il nuovo stato e viene svuotata la lista Visited che
rappresenta gli stati visitati con le epsilon transizioni, mentre l'ultima
clausola rappresenta una epsilon transizione che viene cercata tramite
il predicato nfsa_epsilon_transition/3, verifica che lo stato di partenza
della epsilon transizione non sia presente nella lista Visited infine
richiama ricorsivamente l'accept/4 sulla stringa in input invariata, sul
prossimo stato individuato dalla epsilon transizione e sulla lista
Visited ottenuta aggiungendo a se stessa lo stato di partenza della
epsilon transizione.

Nel predicato accept/4 non sono stati messi i cut per non impedire il
backtracking siccome in molti casi ci sono più strade possibili per
arrivare alla soluzione.


4. nfsa_delete_all/0 e nfsa_delete/1

nfsa_delete_all.
nfsa_delete(FA_Id).


Sono i predicati usati per rimuovere, tramite retractall/1, la conoscenza
dinamica dei fatti che rappresentano gli NFSA dalla base di conoscenza
Prolog, cioè eliminando tutti i fatti creati da nfsa_delta/4, nfsa_init/2,
nfsa_final/2 e nfsa_epsilon_transition/3. Nello specifico nfsa_delete_all/0
rimuove tutti i fatti di tutti gli automi, mentre nfsa_delete/1 rimuove
tutti i fatti di un automa specifico riconosciuto dall'identificatore
univoco FA_Id, passato come argomento al predicato. Il predicato
nfsa_delete_all/0 restituisce true anche se non è stato creato alcun
automa perchè l'idea è che quando viene chiamato non esiste più nessun
automa.




Alcuni esempi:



- Simbolo epsilon 

? - is_regex(c()).
true.

? - is_regex(z()).
true.

? - is_regex(a()).
true.

? - is_regex(o()).
true.



- Termini composti con funtore non riservato

? - is_regex(foo(bar, z(1,2), baz())).
true.

? - is_regex(foo(bar, z(1,X))).
false.



- Creazione automi con simbolo epsilon

? - nfsa_compile_regex(nfsa1, a(a(), 1)).
true.

? - nfsa_recognize(nfsa1, []).
true.

? - nfsa_recognize(nfsa1, [1]).
true.

? - nfsa_recognize(nfsa1, [[]]).
false.

? - nfsa_compile_regex(nfsa3, c(c(), 1)).
true.

? - nfsa_recognize(nfsa3, [1]).
true.

? - nfsa_recognize(nfsa3, []).
false.



- Creazione automa di un termine composto con funtore non riservato

? - nfsa_compile_regex(nfsa2, foo(bar, z(1,2))).
true.

? - nfsa_recognize(nfsa2, [foo(bar, z(1,2))]).
true.

