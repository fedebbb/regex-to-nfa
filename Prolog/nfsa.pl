%%% -*- Mode: Prolog -*-

%%% nfsa.pl


:- dynamic nfsa_init/2.
:- dynamic nfsa_final/2.
:- dynamic nfsa_delta/4.
:- dynamic nfsa_epsilon_transition/3.


%% is_regex/1.

% Caso base: Atomo.

is_regex(RE) :-
    atomic(RE),
    !.

% Caso variabile.

is_regex(RE) :-
    var(RE),
    !,
    fail.

% Termini composti con funtori riservati e 0 argomenti per indicare epsilon.

is_regex(RE) :-
    functor(RE, c, N, _),
    N = 0,
    !.

is_regex(RE) :-
    functor(RE, a, N, _),
    N = 0,
    !.

is_regex(RE) :-
    functor(RE, z, N, _),
    N = 0,
    !.

is_regex(RE) :-
    functor(RE, o, N, _),
    N = 0,
    !.

% Termini composti con funtore non riservato senza argomenti.

is_regex(RE) :-
    compound(RE),
    functor(RE, F, N, _),
    F \= a,
    F \= z,
    F \= c,
    F \= o,
    N = 0,
    !.

% Caso sequenza con argomenti.

is_regex(RE) :-
    RE =.. [c | Args],
    Args = [_, _ | _],
    regex_list(Args),
    !.

% Caso alternativa con argomenti.

is_regex(RE) :-
    RE =.. [a | Args],
    Args = [_, _ | _],
    regex_list(Args),
    !.

% Caso chiusura di kleene (0 o piu volte) con argomenti.

is_regex(z(RE)) :-
    is_regex(RE),
    !.

% Caso ripetizione (1 o piu volte) con argomenti.

is_regex(o(RE)) :-
    is_regex(RE),
    !.

% Caso termini composti con funtore non riservato e argomenti.

is_regex(RE) :-
    compound(RE),
    RE =.. [F | Args],
    F \= a,
    F \= z,
    F \= o,
    F \= c,
    regex_list_comp(Args).





%% regex_list/1.

% Argomenti multipli nei termini composti con funtore riservato.

% Caso base: lista vuota.

regex_list([]).

% Caso ricorsivo.

regex_list([H | T]) :-
    is_regex(H),
    regex_list(T).




%% regex_list_comp/1.

% Argomenti multipli nei termini composti con funtore non riservato.

% Caso base: lista vuota.

regex_list_comp([]).

% Caso argomento non compound.

regex_list_comp([H | T]) :-
    nonvar(H),
    \+ compound(H),
    regex_list_comp(T),
    !.

% Caso argomento compound con 0 argomenti.

regex_list_comp([H | T]) :-
    nonvar(H),
    functor(H, _, N, _),
    N = 0,
    regex_list_comp(T),
    !.

% Caso argomento compound con argomenti multipli.

regex_list_comp([H | T]) :-
    nonvar(H),
    H =.. [_ | Args],
    regex_list_comp(Args),
    regex_list_comp(T),
    !.




%% nfsa_compile_regex/2.

nfsa_compile_regex(FA_Id, RE) :-
    is_regex(RE),
    checking_nfsa_id(FA_Id),
    nfsa_init(FA_Id, _),
    nfsa_delete(FA_Id),
    nfsa_create(FA_Id, RE, _, Start, Final),
    assertz(nfsa_init(FA_Id, Start)),
    assertz(nfsa_final(FA_Id, Final)),
    !.

nfsa_compile_regex(FA_Id, RE) :-
    is_regex(RE),
    checking_nfsa_id(FA_Id),
    nfsa_create(FA_Id, RE, _, Start, Final),
    assertz(nfsa_init(FA_Id, Start)),
    assertz(nfsa_final(FA_Id, Final)).

%% nfsa_create/5

% Predicato per creare automa.


% Caso base: Atomo.

nfsa_create(FA_Id, RE, Delta, Start, Final) :-
    atomic(RE),
    gensym(q, Start),
    gensym(q, Final),
    Delta = [Start, RE, Final],
    assertz(nfsa_delta(FA_Id, Start, RE, Final)),
    !.

% Casi compound senza argomenti quindi automa per epsilon.

nfsa_create(FA_Id, RE, _, Start, Final) :-
    functor(RE, c, N, _),
    N = 0,
    gensym(q, Start),
    gensym(q, Final),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Final)),
    !.

nfsa_create(FA_Id, RE, _, Start, Final) :-
    functor(RE, a, N, _),
    N = 0,
    gensym(q, Start),
    gensym(q, Final),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Final)),
    !.

nfsa_create(FA_Id, RE, _, Start, Final) :-
    functor(RE, z, N, _),
    N = 0,
    gensym(q, Start),
    gensym(q, Final),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Final)),
    !.

nfsa_create(FA_Id, RE, _, Start, Final) :-
    functor(RE, o, N, _),
    N = 0,
    gensym(q, Start),
    gensym(q, Final),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Final)),
    !.

% Caso compound con funtore non riservato e 0 argomenti.

nfsa_create(FA_Id, RE, Delta, Start, Final) :-
    compound(RE),
    functor(RE, _, N, _),
    N = 0,
    gensym(q, Start),
    gensym(q, Final),
    Delta = [Start, RE, Final],
    assertz(nfsa_delta(FA_Id, Start, RE, Final)),
    !.

% Caso sequenza con argomenti.


nfsa_create(FA_Id, RE, _, Start, Final) :-
    RE =.. [c | Args],
    nfsa_create_concat(FA_Id, Args, Start, Final),
    !.

% Caso alternativa con argomenti.

nfsa_create(FA_Id, RE, _, Start, Final) :-
    RE =.. [a | Args],
    gensym(q, Start),
    gensym(q, Final),
    nfsa_create_alt(FA_Id, Args, Start, Final),
    !.

% Caso chiusura di kleene (0 o piu volte) con argomenti.

nfsa_create(FA_Id, z(RE), _, Start, Final) :-
    gensym(q, Start),
    gensym(q, Final),
    nfsa_create(FA_Id, RE, _, Start1, Final1),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Final)),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Start1)),
    assertz(nfsa_epsilon_transition(FA_Id, Final1, Final)),
    assertz(nfsa_epsilon_transition(FA_Id, Final1, Start1)),
    !.


% Caso ripetizione (1 o piu volte) con argomenti.

nfsa_create(FA_Id, o(RE), _, Start, Final) :-
    gensym(q, Start),
    gensym(q, Final),
    nfsa_create(FA_Id, RE, _, Start1, Final1),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Start1)),
    assertz(nfsa_epsilon_transition(FA_Id, Final1, Final)),
    assertz(nfsa_epsilon_transition(FA_Id, Final1, Start1)),
    !.

% Caso compound con argomenti.

nfsa_create(FA_Id, RE, Delta, Start, Final) :-
    compound(RE),
    gensym(q, Start),
    gensym(q, Final),
    Delta = [Start, RE, Final],
    assertz(nfsa_delta(FA_Id, Start, RE, Final)),
    !.
    

%% checking_args/1.

% Gestione argomenti del termine composto nel id automa.

% Caso base: Lista vuota.

checking_args([]).

% Caso ricorsivo: elementi multipli.

checking_args([H | T]) :-
    checking_nfsa_id(H),
    checking_args(T).



%% checking_nfsa_id/1.

% Gestione variabili non istanziate nel id automa.

% Casi variabile.

checking_nfsa_id(FA_Id) :-
    var(FA_Id),
    !,
    fail.

% Caso compound con 0 argomenti.

checking_nfsa_id(FA_Id) :-
    functor(FA_Id, _, N, _),
    N = 0,
    !.

% Caso compound.

checking_nfsa_id(FA_Id) :-
    compound(FA_Id),
    FA_Id =.. [_ | Args],
    checking_args(Args),
    !.

% Caso atomo.

checking_nfsa_id(FA_Id) :-
    atomic(FA_Id),
    !.



%% nfsa_create_alt/4.

% Gestione argomenti multipli del termine composto alternativa.

% Caso base: Lista vuota.

nfsa_create_alt(_, [], _, _).

% Caso ricorsivo: elementi multipli.

nfsa_create_alt(FA_Id, [H | T], Start, Final) :-
    nfsa_create(FA_Id, H, _, Start1, Final1),
    assertz(nfsa_epsilon_transition(FA_Id, Start, Start1)),
    assertz(nfsa_epsilon_transition(FA_Id, Final1, Final)),
    nfsa_create_alt(FA_Id, T, Start, Final).


%% nfsa_create_concat/4.

% Gestione argomenti multipli del termine composto sequenza.

% Caso base: un solo elemento.

nfsa_create_concat(FA_Id, [H], Start, Final) :-
    nfsa_create(FA_Id, H, _, Start, Final).

% Caso ricorsivo: elementi multipli.

nfsa_create_concat(FA_Id, [H | T], Start, Final) :-
    nfsa_create(FA_Id, H, _, Start1, Final1),
    nfsa_create_concat(FA_Id, T, Start2, Final2),
    assertz(nfsa_epsilon_transition(FA_Id, Final1, Start2)),
    Start = Start1,
    Final = Final2.




%% nfsa_recognize/2.

nfsa_recognize(FA_Id, Input) :-
    nfsa_init(FA_Id, StartState),
    accept(FA_Id, Input, StartState, []).


%% accept/3.

% Predicato per verificare se automa accetta la stringa o no.

% Caso base: Stringa vuota.

accept(FA_Id, [], State, _) :-
    nfsa_final(FA_Id, State).


% Caso ricorsivo consumando un simbolo.

accept(FA_Id, [H | T], State, _) :-
    nfsa_delta(FA_Id, State, H, Next),
    accept(FA_Id, T, Next, []).

% Caso ricorsivo epsilon transizione senza consumare simboli.

accept(FA_Id, Input, State, Visited) :-
    nfsa_epsilon_transition(FA_Id, State, Next),
    \+ member(State, Visited),
    accept(FA_Id, Input, Next, [State | Visited]).



%% nfsa_delete_all/0.

% Predicato per eliminare tutti gli automi.

nfsa_delete_all() :-
    retractall(nfsa_delta(_, _, _, _)),
    retractall(nfsa_epsilon_transition(_, _, _)),
    retractall(nfsa_init(_, _)),
    retractall(nfsa_final(_, _)).


%% nfsa_delete/1.

% Predicato per eliminare automa passato.

nfsa_delete(FA_Id) :-
    nonvar(FA_Id),
    nfsa_init(FA_Id, _),
    retractall(nfsa_delta(FA_Id, _, _, _)),
    retractall(nfsa_epsilon_transition(FA_Id, _, _)),
    retractall(nfsa_init(FA_Id, _)),
    retractall(nfsa_final(FA_Id, _)).






%%% nfsa.pl ends here.
