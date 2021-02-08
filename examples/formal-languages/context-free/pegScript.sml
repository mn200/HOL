open HolKernel Parse boolLib bossLib
open boolSimps
open grammarTheory finite_mapTheory
open locationTheory

val _ = new_theory "peg"

(* Based on
     Koprowski and Binzstok, "TRX: A Formally Verified Parser Interpreter".
     LMCS vol 7, no. 2. 2011.
     DOI: 10.2168/LMCS-7(2:18)2011
*)

Datatype:
  pegsym =
    empty 'c
  | any  (('a # locs) -> 'c)
  | tok ('a -> bool) (('a # locs) -> 'c)
  | nt ('b inf) ('c -> 'c)
  | seq pegsym pegsym ('c  -> 'c -> 'c)
  | choice pegsym pegsym ('c + 'c -> 'c)
  | rpt pegsym ('c list -> 'c)
  | not pegsym 'c
  | error 'e
End

Datatype:
  peg = <| start : ('a,'b,'c,'e) pegsym ;
           anyEOF : 'e ;
           tokFALSE : 'e ; tokEOF : 'e;
           notFAIL : 'e;
           rules : 'b inf |-> ('a,'b,'c,'e) pegsym |>
End

Datatype:
  pegresult = Success 'a 'c
            | Failure locs 'e
End
Definition isSuccess_def[simp]:
  isSuccess (Success _ _) = T ∧
  isSuccess (Failure _ _) = F
End
Definition isFailure_def[simp]:
  isFailure (Success _ _) = F ∧
  isFailure (Failure _ _) = T
End

Definition resultmap_def[simp]:
  resultmap f (Success a c) = Success a (f c) ∧
  resultmap f (Failure fl fe) = Failure fl fe
End
Theorem resultmap_EQ_Success :
  resultmap f r = Success a x ⇔ ∃x0. r = Success a x0 ∧ x = f x0
Proof
  Cases_on ‘r’ >> simp[] >> metis_tac[]
QED

Theorem resultmap_EQ_Failure[simp]:
  (resultmap f r = Failure fl fe ⇔ r = Failure fl fe) ∧
  (Failure fl fe = resultmap f r ⇔ r = Failure fl fe)
Proof
  Cases_on ‘r’ >> simp[] >> metis_tac[]
QED
Definition rmax_def[simp]:
  rmax (Success a c) _ = Success a c ∧
  rmax (Failure _ _) (Success a c) = Success a c ∧
  rmax (Failure fl1 fe1) (Failure fl2 fe2) =
  if locsle fl1 fl2 then Failure fl2 fe2 else Failure fl1 fe1
End

Theorem rmax_EQ_Success:
  rmax r1 r2 = Success x y ⇔
  r1 = Success x y ∨ r2 = Success x y ∧ isFailure r1
Proof
  Cases_on ‘r1’ >> simp[] >> Cases_on ‘r2’ >> simp[AllCaseEqs()]
QED

Theorem result_cases[local] = TypeBase.nchotomy_of “:(α,β,γ) pegresult”

Definition sloc_def:
  sloc [] = Locs end_locn end_locn ∧
  sloc (h::t) = SND h
End

Theorem sloc_thm[simp]:
  sloc [] = Locs end_locn end_locn ∧
  sloc ((c,l) :: t) = l
Proof
  simp[sloc_def]
QED

(* Option type should be replaced with sum type (loc. for NONE *)
Inductive peg_eval:
  (∀s c. peg_eval G (s, empty c) (Success s c)) ∧
  (∀n r s f c.
       n ∈ FDOM G.rules ∧ peg_eval G (s, G.rules ' n) (Success r c) ⇒
       peg_eval G (s, nt n f) (Success r (f c))) ∧
  (∀n s f fe fl.
       n ∈ FDOM G.rules ∧ peg_eval G (s, G.rules ' n) (Failure fl fe) ⇒
       peg_eval G (s, nt n f) (Failure fl fe)) ∧
  (∀h t f. peg_eval G (h::t, any f) (Success t (f h))) ∧
  (∀f. peg_eval G
                ([] : ('a # locs) list, any f)
                (Failure (sloc ([] : ('a # locs) list)) G.anyEOF)) ∧
  (∀e t P f. P (FST e) ⇒ peg_eval G (e::t, tok P f) (Success t (f e))) ∧
  (∀e t P f.
     ¬P (FST e) ⇒
     peg_eval G (e::t, tok P f) (Failure (sloc (e::t)) G.tokFALSE)) ∧
  (∀P f. peg_eval G ([], tok P f)
                  (Failure (sloc ([] : ('a # locs) list)) G.tokEOF)) ∧
  (∀e s c fr.
     peg_eval G (s, e) fr ∧ isFailure fr ⇒
     peg_eval G (s, not e c) (Success s c)) ∧
  (∀e s r c.
     peg_eval G (s, e) r ∧ isSuccess r ⇒
     peg_eval G (s, not e c) (Failure (sloc s) G.notFAIL))  ∧
  (∀e1 e2 s f fr.
     peg_eval G (s, e1) fr ∧ isFailure fr ⇒ peg_eval G (s, seq e1 e2 f) fr)  ∧
  (∀e1 e2 s0 s1 c1 fr.
     peg_eval G (s0, e1) (Success s1 c1) ∧
     peg_eval G (s1, e2) fr ∧ isFailure fr ⇒
     peg_eval G (s0, seq e1 e2 f) fr) ∧
  (∀e1 e2 s0 s1 s2 c1 c2 f.
     peg_eval G (s0, e1) (Success s1 c1) ∧
     peg_eval G (s1, e2) (Success s2 c2) ⇒
     peg_eval G (s0, seq e1 e2 f) (Success s2 (f c1 c2))) ∧
  (∀e1 e2 s f f1 f2.
     peg_eval G (s, e1) f1  ∧ peg_eval G (s, e2) f2 ∧
     isFailure f1 ∧ isFailure f2 ⇒
     peg_eval G (s, choice e1 e2 f) (rmax f1 f2)) ∧
  (∀e1 e2 s f sr.
     peg_eval G (s, e1) sr ∧ isSuccess sr ⇒
     peg_eval G (s, choice e1 e2 f) (resultmap (f o INL) sr)) ∧
  (∀e1 e2 s f fr sr.
     peg_eval G (s, e1) fr ∧ isFailure fr ∧
     peg_eval G (s, e2) sr ∧ isSuccess sr ⇒
     peg_eval G (s, choice e1 e2 f) (resultmap (f o INR) sr)) ∧
  (∀e s. peg_eval G (s, error e) (Failure (sloc s) e)) ∧
[~rpt:]
  (∀e f s s1 list.
     peg_eval_list G (s, e) (s1,list) ⇒
     peg_eval G (s, rpt e f) (Success s1 (f list))) ∧
[~list_nil:]
  (∀e s fr. peg_eval G (s, e) fr ∧ isFailure fr ⇒
            peg_eval_list G (s, e) (s,[])) ∧
[~list_cons:]
  (∀e s0 s1 s2 c cs.
     peg_eval G (s0, e) (Success s1 c) ∧
     peg_eval_list G (s1, e) (s2,cs) ⇒
     peg_eval_list G (s0, e) (s2,c::cs))
End

Theorem peg_eval_strongind' =
  peg_eval_strongind
    |> SIMP_RULE (srw_ss()) [pairTheory.FORALL_PROD]
    |> Q.SPECL [`G`, `\es0 r. P1 (FST es0) (SND es0) r`,
                `\es0 sr. P2 (FST es0) (SND es0) (FST sr) (SND sr)`]
    |> SIMP_RULE (srw_ss()) []

open rich_listTheory
Theorem peg_eval_suffix0[local]:
  (∀s0 e sr. peg_eval G (s0,e) sr ⇒ ∀s r. sr = Success s r ⇒ IS_SUFFIX s0 s) ∧
  ∀s0 e s rl. peg_eval_list G (s0,e) (s,rl) ⇒ IS_SUFFIX s0 s
Proof
  HO_MATCH_MP_TAC peg_eval_strongind' THEN
  SRW_TAC [][IS_SUFFIX_compute, IS_PREFIX_APPEND3, IS_PREFIX_REFL] THEN
  fs[rmax_EQ_Success, resultmap_EQ_Success] >>
  METIS_TAC [IS_PREFIX_TRANS]
QED

(* Theorem 3.1 *)
Theorem peg_eval_suffix =
  peg_eval_suffix0 |> SIMP_RULE (srw_ss() ++ DNF_ss) []

(* Theorem 3.2 *)
Theorem peg_deterministic:
  (∀s0 e sr. peg_eval G (s0,e) sr ⇒ ∀sr'. peg_eval G (s0,e) sr' ⇔ sr' = sr) ∧
  ∀s0 e s rl. peg_eval_list G (s0,e) (s,rl) ⇒
              ∀srl'. peg_eval_list G (s0,e) srl' ⇔ srl' = (s,rl)
Proof
  HO_MATCH_MP_TAC peg_eval_strongind' THEN SRW_TAC [][] THEN
  ONCE_REWRITE_TAC [peg_eval_cases] THEN SRW_TAC [][] THEN
  TRY (Q.MATCH_ASSUM_RENAME_TAC ‘isSuccess result’ >>
       Cases_on ‘result’ >> fs[]) THEN
  TRY (Q.MATCH_ASSUM_RENAME_TAC ‘isFailure result’ >>
       Cases_on ‘result’ >> fs[]) THEN csimp[] THEN
  Q.MATCH_ASSUM_RENAME_TAC ‘isFailure result2’ >> Cases_on ‘result2’ >> fs[]
QED

(* Lemma 3.3 *)
Theorem peg_badrpt:
  peg_eval G (s0,e) (Success s0 r) ⇒ ∀r. ¬peg_eval G (s0, rpt e f) r
Proof
  strip_tac >> simp[Once peg_eval_cases] >> map_every qx_gen_tac [`s1`, `l`] >>
  disch_then (assume_tac o MATCH_MP (CONJUNCT2 peg_deterministic)) >>
  `peg_eval_list G (s0,e) (s1,r::l)`
    by METIS_TAC [last (peg_eval_rules |> SPEC_ALL |> CONJUNCTS)] >>
  pop_assum mp_tac >> simp[]
QED

Inductive peg0:
  (∀c. peg0 G (empty c)) ∧

  (* any *)
  (∀f. peggt0 G (any f)) ∧
  (∀f. pegfail G (any f)) ∧

  (* tok *)
  (∀t f. peggt0 G (tok t f)) ∧
  (∀t f. pegfail G (tok t f)) ∧

  (* rpt *)
  (∀e f. pegfail G e ⇒ peg0 G (rpt e f)) ∧
  (∀e f. peggt0 G e ⇒ peggt0 G (rpt e f)) ∧

  (* nt rules *)
  (∀n f. n ∈ FDOM G.rules ∧ peg0 G (G.rules ' n) ⇒
         peg0 G (nt n f)) ∧
  (∀n f. n ∈ FDOM G.rules ∧ peggt0 G (G.rules ' n) ⇒
         peggt0 G (nt n f)) ∧
  (∀n f. n ∈ FDOM G.rules ∧ pegfail G (G.rules ' n) ⇒
         pegfail G (nt n f)) ∧

  (* seq rules *)
  (∀e1 e2 f. pegfail G e1 ∨ (peg0 G e1 ∧ pegfail G e2) ∨
             (peggt0 G e1 ∧ pegfail G e2) ⇒
             pegfail G (seq e1 e2 f)) ∧
  (∀e1 e2 f. peggt0 G e1 ∧ (peg0 G e2 ∨ peggt0 G e2) ∨
             (peg0 G e1 ∨ peggt0 G e1) ∧ peggt0 G e2 ⇒
             peggt0 G (seq e1 e2 f)) ∧
  (∀e1 e2 f. peg0 G e1 ∧ peg0 G e2 ⇒ peg0 G (seq e1 e2 f)) ∧

  (* choice rules *)
  (∀e1 e2 f. peg0 G e1 ∨ (pegfail G e1 ∧ peg0 G e2) ⇒
             peg0 G (choice e1 e2 f)) ∧
  (∀e1 e2 f. pegfail G e1 ∧ pegfail G e2 ⇒ pegfail G (choice e1 e2 f)) ∧
  (∀e1 e2 f. peggt0 G e1 ∨ (pegfail G e1 ∧ peggt0 G e2) ⇒
             peggt0 G (choice e1 e2 f)) ∧

  (* not *)
  (∀e c. pegfail G e ⇒ peg0 G (not e c)) ∧
  (∀e c. peg0 G e ∨ peggt0 G e ⇒ pegfail G (not e c)) ∧

  (* error *)
  (∀e. pegfail G (error e))
End

Theorem peg0_error[simp]:
  ¬peg0 G (error e)
Proof
  simp[Once peg0_cases]
QED

Theorem peg_eval_suffix':
  peg_eval G (s0,e) (Success s c) ⇒
  s0 = s ∨ IS_SUFFIX s0 s ∧ LENGTH s < LENGTH s0
Proof
  strip_tac >> imp_res_tac peg_eval_suffix >> Cases_on `s0 = s` >- simp[] >>
  fs[IS_SUFFIX_compute] >>
  imp_res_tac IS_PREFIX_LENGTH >> fs[] >>
  qsuff_tac `LENGTH s ≠ LENGTH s0` >- (strip_tac >> decide_tac) >>
  strip_tac >>
  metis_tac [IS_PREFIX_LENGTH_ANTI, LENGTH_REVERSE, REVERSE_REVERSE]
QED

Theorem peg_eval_list_suffix':
  peg_eval_list G (s0, e) (s,rl) ⇒
  s0 = s ∨ IS_SUFFIX s0 s ∧ LENGTH s < LENGTH s0
Proof
  strip_tac >> imp_res_tac peg_eval_suffix >> Cases_on `s0 = s` >- simp[] >>
  fs[IS_SUFFIX_compute] >> imp_res_tac IS_PREFIX_LENGTH >> fs[] >>
  qsuff_tac `LENGTH s ≠ LENGTH s0` >- (strip_tac >> decide_tac) >> strip_tac >>
  metis_tac [IS_PREFIX_LENGTH_ANTI, LENGTH_REVERSE, REVERSE_REVERSE]
QED

fun rule_match th = FIRST (List.mapPartial (total MATCH_MP_TAC)
                                           (th |> SPEC_ALL |> CONJUNCTS))

Theorem FORALL_result:
  (∀r. P r) ⇔ (∀a c. P (Success a c)) ∧ (∀fl fe. P (Failure fl fe))
Proof
  rw[EQ_IMP_THM] >> Cases_on ‘r’ >> simp[]
QED

Theorem EXISTS_result:
  (∃r. P r) ⇔ (∃a c. P (Success a c)) ∨ (∃fl fe. P (Failure fl fe))
Proof
  rw[EQ_IMP_THM] >- (Cases_on ‘r’ >> metis_tac[]) >> metis_tac[]
QED

Theorem lemma4_1a0[local]:
  (∀s0 e r. peg_eval G (s0, e) r ⇒
            (∀c. r = Success s0 c ⇒ peg0 G e) ∧
            (isFailure r ⇒ pegfail G e) ∧
            (∀s c. r = Success s c ∧ LENGTH s < LENGTH s0 ⇒ peggt0 G e)) ∧
  (∀s0 e s rl. peg_eval_list G (s0,e) (s,rl) ⇒
               (s0 = s ⇒ pegfail G e) ∧
               (LENGTH s < LENGTH s0 ⇒ peggt0 G e))
Proof
  ho_match_mp_tac peg_eval_strongind' >> simp[peg0_rules, FORALL_result] >>
  rpt conj_tac
  >- (rpt strip_tac >> imp_res_tac peg_eval_suffix' >> fs[peg0_rules])
  >- (rpt strip_tac >> rule_match peg0_rules >>
      imp_res_tac peg_eval_suffix' >> fs[] >> rw[] >>
      full_simp_tac (srw_ss() ++ ARITH_ss) [])
  >- (rpt strip_tac >> rule_match peg0_rules >>
      imp_res_tac peg_eval_suffix' >> fs[] >> rw[] >>
      full_simp_tac (srw_ss() ++ ARITH_ss) [])
  >- simp[AllCaseEqs()] >>
  rpt strip_tac
  >- (first_x_assum match_mp_tac >> rw[] >>
      imp_res_tac peg_eval_suffix >> fs[IS_SUFFIX_compute] >>
      imp_res_tac IS_PREFIX_LENGTH >> fs[] >>
      `LENGTH s = LENGTH s0'` by decide_tac >>
      metis_tac [IS_PREFIX_LENGTH_ANTI, LENGTH_REVERSE, REVERSE_REVERSE]) >>
  imp_res_tac peg_eval_suffix' >- rw[] >>
  imp_res_tac peg_eval_list_suffix' >- rw[] >>
  asm_simp_tac (srw_ss() ++ ARITH_ss) []
QED

Theorem lemma4_1a = lemma4_1a0 |> SIMP_RULE (srw_ss() ++ DNF_ss) [AND_IMP_INTRO]

Inductive wfpeg:
  (∀n f. n ∈ FDOM G.rules ∧ wfpeg G (G.rules ' n) ⇒ wfpeg G (nt n f)) ∧
[~_empty[simp]:]
  (∀c. wfpeg G (empty c)) ∧
[~_any[simp]:]
  (∀f. wfpeg G (any f)) ∧
[~tok[simp]:]
  (∀t f. wfpeg G (tok t f)) ∧
[~_error[simp]:]
  (∀e. wfpeg G (error e)) ∧
  (∀e c. wfpeg G e ⇒ wfpeg G (not e c)) ∧
  (∀e1 e2 f. wfpeg G e1 ∧ (peg0 G e1 ⇒ wfpeg G e2) ⇒
             wfpeg G (seq e1 e2 f)) ∧
  (∀e1 e2 f. wfpeg G e1 ∧ wfpeg G e2 ⇒ wfpeg G (choice e1 e2 f)) ∧
  (∀e f. wfpeg G e ∧ ¬peg0 G e ⇒ wfpeg G (rpt e f))
End

Definition subexprs_def[simp]:
  (subexprs (any f1) = { any f1 }) ∧
  (subexprs (empty c) = { empty c }) ∧
  (subexprs (tok t f2) = { tok t f2 }) ∧
  (subexprs (error e) = { error e }) ∧
  (subexprs (nt s f) = { nt s f }) ∧
  (subexprs (not e c) = not e c INSERT subexprs e) ∧
  (subexprs (seq e1 e2 f3) = seq e1 e2 f3 INSERT subexprs e1 ∪ subexprs e2) ∧
  (subexprs (choice e1 e2 f4) =
    choice e1 e2 f4 INSERT subexprs e1 ∪ subexprs e2) ∧
  (subexprs (rpt e f5) = rpt e f5 INSERT subexprs e)
End

Theorem subexprs_included[simp]: e ∈ subexprs e
Proof Induct_on `e` >> srw_tac[][subexprs_def]
QED

Definition Gexprs_def:
  Gexprs G = BIGUNION (IMAGE subexprs (G.start INSERT FRANGE G.rules))
End

Theorem start_IN_Gexprs[simp]:
  G.start ∈ Gexprs G
Proof
  simp[Gexprs_def, subexprs_included]
QED

val wfG_def = Define`wfG G ⇔ ∀e. e ∈ Gexprs G ⇒ wfpeg G e`;

Theorem IN_subexprs_TRANS:
  ∀a b c. a ∈ subexprs b ∧ b ∈ subexprs c ⇒ a ∈ subexprs c
Proof
  Induct_on `c` >> simp[] >> rpt strip_tac >> fs[] >> metis_tac[]
QED

Theorem Gexprs_subexprs:
  e ∈ Gexprs G ⇒ subexprs e ⊆ Gexprs G
Proof
  simp_tac (srw_ss() ++ DNF_ss) [Gexprs_def, pred_setTheory.SUBSET_DEF] >>
  strip_tac >> metis_tac [IN_subexprs_TRANS]
QED

Theorem IN_Gexprs_E:
  (not e c ∈ Gexprs G ⇒ e ∈ Gexprs G) ∧
  (seq e1 e2 f ∈ Gexprs G ⇒ e1 ∈ Gexprs G ∧ e2 ∈ Gexprs G) ∧
  (choice e1 e2 f2 ∈ Gexprs G ⇒ e1 ∈ Gexprs G ∧ e2 ∈ Gexprs G) ∧
  (rpt e f3 ∈ Gexprs G ⇒ e ∈ Gexprs G)
Proof
  rpt strip_tac >> imp_res_tac Gexprs_subexprs >> fs[] >>
  metis_tac [pred_setTheory.SUBSET_DEF, subexprs_included]
QED

val pair_CASES = pairTheory.pair_CASES
val option_CASES = optionTheory.option_nchotomy
val list_CASES = listTheory.list_CASES

Theorem reducing_peg_eval_makes_list[local]:
  (∀s. LENGTH s < n ⇒ ∃r. peg_eval G (s, e) r) ∧ ¬peg0 G e ∧ LENGTH s0 < n ⇒
  ∃s' rl. peg_eval_list G (s0,e) (s',rl)
Proof
  strip_tac >> completeInduct_on `LENGTH s0` >> rw[] >>
  full_simp_tac (srw_ss() ++ DNF_ss ++ ARITH_ss) [] >>
  ‘(∃fl fe. peg_eval G (s0,e) (Failure fl fe)) ∨
   ∃s1 c. peg_eval G (s0,e) (Success s1 c)’
    by metis_tac [result_cases]
  >- metis_tac [peg_eval_rules,isFailure_def, isSuccess_def] >>
  `s0 ≠ s1` by metis_tac [lemma4_1a] >>
  `LENGTH s1 < LENGTH s0` by metis_tac [peg_eval_suffix'] >>
  metis_tac [peg_eval_rules]
QED

Theorem peg_eval_total:
  wfG G ⇒ ∀s e. e ∈ Gexprs G ⇒ ∃r. peg_eval G (s,e) r
Proof
  simp[wfG_def] >> strip_tac >> gen_tac >>
  completeInduct_on ‘LENGTH s’ >>
  full_simp_tac (srw_ss() ++ DNF_ss) [] >> rpt strip_tac >>
  ‘wfpeg G e’ by metis_tac[] >>
  Q.UNDISCH_THEN ‘e ∈ Gexprs G’ mp_tac >>
  pop_assum mp_tac >> qid_spec_tac ‘e’ >>
  Induct_on ‘wfpeg’ >> rw[]
  >- ((* nt *)
      qsuff_tac ‘G.rules ' n ∈ Gexprs G’
      >- (strip_tac >>
          first_x_assum $ drule_then
                        $ qx_choose_then ‘result’ strip_assume_tac >>
          Cases_on ‘result’ >>
          metis_tac [peg_eval_rules]) >>
      asm_simp_tac (srw_ss() ++ DNF_ss) [Gexprs_def, FRANGE_DEF] >>
      metis_tac [subexprs_included])
  >- (* empty *) metis_tac [peg_eval_rules]
  >- (* any *) metis_tac [peg_eval_rules, list_CASES]
  >- (* tok *) metis_tac [peg_eval_rules, list_CASES]
  >- (* error *) metis_tac[peg_eval_rules]
  >- (* not *) metis_tac [peg_eval_rules, result_cases, IN_Gexprs_E,
                          isSuccess_def, isFailure_def]
  >- ((* seq *) rename [‘seq e1 e2 f ∈ Gexprs G’] >>
      ‘e1 ∈ Gexprs G’ by imp_res_tac IN_Gexprs_E >>
      ‘(∃fl fe. peg_eval G (s,e1) (Failure fl fe))  ∨
       ∃s' c. peg_eval G (s,e1) (Success s' c)’
        by metis_tac[result_cases]
      >- metis_tac [peg_eval_rules, isFailure_def, isSuccess_def] >>
      Cases_on ‘s' = s’
      >- (‘peg0 G e1’ by metis_tac [lemma4_1a] >>
          ‘e2 ∈ Gexprs G’ by imp_res_tac IN_Gexprs_E >>
          metis_tac [peg_eval_rules, result_cases, isSuccess_def,
                     isFailure_def]) >>
      ‘LENGTH s' < LENGTH s’ by metis_tac [peg_eval_suffix'] >>
      ‘∃r'. peg_eval G (s',e2) r'’ by metis_tac [IN_Gexprs_E] >>
      metis_tac [result_cases, peg_eval_rules, isFailure_def, isSuccess_def])
  >- (* choice *)
    (drule_then strip_assume_tac (cj 3 IN_Gexprs_E) >> fs[] >>
     metis_tac [peg_eval_rules, result_cases, isSuccess_def, isFailure_def]) >>
  (* rpt *) imp_res_tac IN_Gexprs_E >>
  ‘(∃fl fe. peg_eval G (s, e) (Failure fl fe)) ∨
   ∃s' c. peg_eval G (s,e) (Success s' c)’
    by metis_tac [result_cases]
  >- (‘peg_eval_list G (s,e) (s,[])’
        by metis_tac [peg_eval_rules, isFailure_def] >>
      metis_tac [peg_eval_rules]) >>
  ‘s' ≠ s’ by metis_tac [lemma4_1a] >>
  ‘LENGTH s' < LENGTH s’ by metis_tac [peg_eval_suffix'] >>
  metis_tac [peg_eval_rules, reducing_peg_eval_makes_list]
QED

(* derived and useful PEG forms *)
Definition pegf_def:  pegf sym f = seq sym (empty ARB) (λl1 l2. f l1)
End

val ignoreL_def = Define`
  ignoreL s1 s2 = seq s1 s2 (λa b. b)
`;
val _ = set_mapped_fixity{fixity = Infixl 500, term_name = "ignoreL",
                          tok = "~>"}

val ignoreR_def = Define`
  ignoreR s1 s2 = seq s1 s2 (λa b. a)
`;
val _ = set_mapped_fixity{fixity = Infixl 500, term_name = "ignoreR",
                          tok = "<~"}

val choicel_def = Define`
  (choicel [] = not (empty ARB) ARB) ∧
  (choicel (h::t) = choice h (choicel t) (λs. sum_CASE s I I))
`;

val checkAhead_def = Define`
  checkAhead P s = not (not (tok P ARB) ARB) ARB ~> s
`;

Theorem peg_eval_seq_SOME:
  peg_eval G (i0, seq s1 s2 f) (Success i r) ⇔
    ∃i1 r1 r2. peg_eval G (i0, s1) (Success i1 r1) ∧
               peg_eval G (i1, s2) (Success i r2) ∧ (r = f r1 r2)
Proof simp[Once peg_eval_cases] >> metis_tac[]
QED

Theorem peg_eval_seq_NONE:
  peg_eval G (i0, seq s1 s2 f) (Failure fl fe) ⇔
  peg_eval G (i0, s1) (Failure fl fe) ∨
  ∃i r. peg_eval G (i0,s1) (Success i r) ∧
        peg_eval G (i,s2) (Failure fl fe)
Proof
  simp[Once peg_eval_cases] >> metis_tac[]
QED

Theorem peg_eval_tok_NONE =
  “peg_eval G (i, tok P f) (Failure fl fe)”
    |> SIMP_CONV (srw_ss()) [Once peg_eval_cases]

Theorem peg_eval_tok_SOME:
  peg_eval G (i0, tok P f) (Success i r) ⇔
  ∃h. P (FST h) ∧ i0 = h::i ∧ r = f h
Proof simp[Once peg_eval_cases] >> metis_tac[]
QED

Theorem peg_eval_empty[simp]: peg_eval G (i, empty r) x ⇔ x = Success i r
Proof simp[Once peg_eval_cases]
QED

Theorem peg_eval_NT_SOME:
  peg_eval G (i0,nt N f) (Success i r) ⇔
  ∃r0. r = f r0 ∧ N ∈ FDOM G.rules ∧
       peg_eval G (i0,G.rules ' N) (Success i r0)
Proof simp[Once peg_eval_cases]
QED

Theorem peg_eval_choice:
  ∀x.
     peg_eval G (i0, choice s1 s2 f) x ⇔
      (∃sr. peg_eval G (i0, s1) sr ∧ isSuccess sr ∧
            x = resultmap (f o INL) sr) ∨
      (∃sr fr.
         peg_eval G (i0, s1) fr ∧ isFailure fr ∧
         peg_eval G (i0, s2) sr ∧ isSuccess sr ∧ x = resultmap (f o INR) sr) ∨
      ∃fr1 fr2.
        peg_eval G (i0, s1) fr1 ∧ peg_eval G (i0, s2) fr2 ∧
        isFailure fr1 ∧ isFailure fr2 ∧ x = rmax fr1 fr2
Proof
  simp[Once peg_eval_cases, SimpLHS] >> metis_tac[]
QED

Theorem peg_eval_choicel_NIL[simp]:
  peg_eval G (i0, choicel []) x = (x = Failure (sloc i0) G.notFAIL)
Proof
  simp[choicel_def, Once peg_eval_cases]
QED

Theorem peg_eval_choicel_CONS:
  ∀x. peg_eval G (i0, choicel (h::t)) x ⇔
      peg_eval G (i0, h) x ∧ isSuccess x ∨
      ∃fr ry.
        peg_eval G (i0,h) fr ∧ isFailure fr ∧ peg_eval G (i0, choicel t) ry ∧
        x = rmax fr ry
Proof
  simp[choicel_def, SimpLHS, Once peg_eval_cases] >>
  dsimp[FORALL_result, resultmap_EQ_Success, rmax_EQ_Success] >>
  conj_tac >- metis_tac[] >>
  dsimp[EXISTS_result, AllCaseEqs()] >> metis_tac[]
QED

Theorem peg_eval_rpt:
  peg_eval G (i0, rpt s f) x ⇔
      ∃i l. peg_eval_list G (i0,s) (i,l) ∧ x = Success i (f l)
Proof simp[Once peg_eval_cases, SimpLHS] >> metis_tac[]
QED

val peg_eval_list = Q.store_thm(
  "peg_eval_list",
  `peg_eval_list G (i0, e) (i, r) ⇔
     ∃fr. peg_eval G (i0, e) fr ∧ isFailure fr ∧ i = i0 ∧ r = [] ∨
     (∃i1 rh rt.
        peg_eval G (i0, e) (Success i1 rh) ∧
        peg_eval_list G (i1, e) (i, rt) ∧ r = rh::rt)`,
  simp[Once peg_eval_cases, SimpLHS] >> metis_tac[]);

Theorem pegfail_empty[simp]:
  pegfail G (empty r) = F
Proof simp[Once peg0_cases]
QED

Theorem peg0_empty[simp]:
  peg0 G (empty r) = T
Proof simp[Once peg0_cases]
QED

Theorem peg0_not[simp]:
  peg0 G (not s r) ⇔ pegfail G s
Proof simp[Once peg0_cases, SimpLHS]
QED

Theorem peg0_choice[simp]:
  peg0 G (choice s1 s2 f) ⇔ peg0 G s1 ∨ pegfail G s1 ∧ peg0 G s2
Proof
  simp[Once peg0_cases, SimpLHS]
QED

Theorem peg0_choicel[simp]:
  (peg0 G (choicel []) = F) ∧
  (peg0 G (choicel (h::t)) ⇔ peg0 G h ∨ pegfail G h ∧ peg0 G (choicel t))
Proof
  simp[choicel_def]
QED

Theorem peg0_seq[simp]:
  peg0 G (seq s1 s2 f) ⇔ peg0 G s1 ∧ peg0 G s2
Proof simp[Once peg0_cases, SimpLHS]
QED

Theorem peg0_tok[simp]:
  peg0 G (tok P f) = F
Proof
  simp[Once peg0_cases]
QED

Theorem peg0_pegf[simp]:
  peg0 G (pegf s f) = peg0 G s
Proof
  simp[pegf_def]
QED

val _ = export_theory()
