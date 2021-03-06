signature patternMatchesLib =
sig
  include Abbrev
  type ssfrag = simpLib.ssfrag

  (********************************)
  (* parsing                      *)
  (********************************)

  (* ENABLE_PMATCH_CASES() turns on parsing for
     PMATCH style case expressions. After calling it
     expressions like `case ... of ...` are not parsed
     to decision trees any more, but to PMATCH expressions.
     Decision tree case expressions are afterwards available
     via `dtcase ... of ...`. *)
  val ENABLE_PMATCH_CASES : unit -> unit


  (********************************)
  (* Naming conventions           *)
  (********************************)

  (* Many PMATCH related tools need to prove various forms of
     preconditions, in particular they need to prove that certain
     patterns are injective or don't overlap. For this they need
     information about the used constructors, in particular
     injectivity theorems about the used constructors and theorems
     about the distinctiveness of constructors. For most conversions
     there are therefore 4 forms:

     XXX_CONV : conv

     uses a default set of theorem for proving preconditions enriched
     with information from TypeBase.

     XXX_CONV_GEN : ssfrag list -> conv

     additionally uses the given list of ssfrags for proving preconditions.

     XXX_ss : ssfrag

     uses the default set + the simplifier using it as a callback to prove
     preconditions.

     XXX_ss_GEN : ssfrag list -> ssfrag

     uses additionally the given list of ssfrags.
  *)


  (********************************)
  (* Normalise PMATCH-terms       *)
  (********************************)

  (* remove unused pattern variables *)
  val PMATCH_CLEANUP_PVARS_CONV : conv

  (* Use same variable names for pattern, guard and rhs *)
  val PMATCH_FORCE_SAME_VARS_CONV : conv

  (* Rename pattern variables unused in guard and rhs into
     wildcards. *)
  val PMATCH_INTRO_WILDCARDS_CONV : conv

  (* Enforce each pattern to have the same number of columns, i.e.
     explicit elements of a top-level tuple. *)
  val PMATCH_EXPAND_COLS_CONV : conv

  (* A combination of the normalisations above. *)
  val PMATCH_NORMALISE_CONV : conv
  val PMATCH_NORMALISE_ss : simpLib.ssfrag

  (********************************)
  (* Evaluate PMATCH-terms        *)
  (********************************)

  (* PMATCH_CLEANUP_CONV removes rows that can't match,
     removes all rows after the first matching row and
     evaluates the whole expression in case the first row matches. *)
  val PMATCH_CLEANUP_CONV : conv
  val PMATCH_CLEANUP_CONV_GEN : ssfrag list -> conv

  val PMATCH_CLEANUP_GEN_ss : ssfrag list -> ssfrag
  val PMATCH_CLEANUP_ss : ssfrag

  (* PMATCH_SIMP_COLS_CONV partially evaluates columns that all contain
     either the same constructor or a variable. *)
  val PMATCH_SIMP_COLS_CONV : conv
  val PMATCH_SIMP_COLS_CONV_GEN : ssfrag list -> conv

  (* A combination of PMATCH_CLEANUP_CONV and PMATCH_SIMP_COLS_CONV *)
  val PMATCH_FAST_SIMP_CONV : conv
  val PMATCH_FAST_SIMP_CONV_GEN : ssfrag list -> conv
  val PMATCH_FAST_SIMP_GEN_ss : ssfrag list -> ssfrag
  val PMATCH_FAST_SIMP_ss : ssfrag


  (********************************)
  (* simplify PMATCH-terms        *)
  (********************************)

  (* Remove easily detectable redundant rows *)
  val PMATCH_REMOVE_FAST_REDUNDANT_CONV : conv
  val PMATCH_REMOVE_FAST_REDUNDANT_CONV_GEN : ssfrag list -> conv

  (* Remove easily detectable subsumed rows *)
  val PMATCH_REMOVE_FAST_SUBSUMED_CONV : bool -> conv
  val PMATCH_REMOVE_FAST_SUBSUMED_CONV_GEN : bool -> ssfrag list -> conv

  (* Full simplification of PMATCH expressions:
     normalise, partially evaluate rows and columns and
     try to remove redundant and subsumed rows. *)
  val PMATCH_SIMP_CONV : conv
  val PMATCH_SIMP_CONV_GEN : ssfrag list -> conv
  val PMATCH_SIMP_GEN_ss : ssfrag list -> ssfrag
  val PMATCH_SIMP_ss : ssfrag


  (********************************)
  (* removing double variable     *)
  (* bindings                     *)
  (********************************)

  val PMATCH_REMOVE_DOUBLE_BIND_CONV_GEN : ssfrag list -> conv
  val PMATCH_REMOVE_DOUBLE_BIND_CONV : conv
  val PMATCH_REMOVE_DOUBLE_BIND_GEN_ss : ssfrag list -> ssfrag
  val PMATCH_REMOVE_DOUBLE_BIND_ss : ssfrag


  (********************************)
  (* removing GUARDS              *)
  (********************************)

  val PMATCH_REMOVE_GUARDS_CONV_GEN : ssfrag list -> conv
  val PMATCH_REMOVE_GUARDS_CONV : conv
  val PMATCH_REMOVE_GUARDS_GEN_ss : ssfrag list -> ssfrag
  val PMATCH_REMOVE_GUARDS_ss : ssfrag


  (********************************)
  (* extending input              *)
  (********************************)

  val PMATCH_EXTEND_INPUT_CONV_GEN : ssfrag list -> term -> conv
  val PMATCH_EXTEND_INPUT_CONV : term -> conv

  (********************************)
  (* removing PMATCH-terms        *)
  (* via lifting it to the nearest*)
  (* boolean term and then        *)
  (* unfolding                    *)
  (********************************)

  (* One can eliminate PMATCHs by unfolding all
     cases explicitly. This is often handy to
     prove properties about functions defined
     via pattern matches without the need to
     do the case-splits manually.

     This tactic looks for the smallest wrapper
     around a PMATCH such that the term is of type
     bool. This term is then expanded into a big
     conjunction. For each case of the pattern match,
     one conjunct is created.

     If the flag "check_exh" is is set to true, the
     conversion tries to prove the exhaustiveness of
     the expanded pattern match. This is slow, but if
     successful allows to eliminate the last
     generated conjunct.
  *)
  val PMATCH_LIFT_BOOL_CONV : bool -> conv

  (* There is also a more generic version that
     allows to provide extra ssfrags. This might
     be handy, if the PMATCH contains functions
     not known by the default methods. *)
  val PMATCH_LIFT_BOOL_CONV_GEN : ssfrag list -> bool -> conv

  (* corresponding ssfrags *)
  val PMATCH_LIFT_BOOL_GEN_ss : ssfrag list -> bool -> ssfrag
  val PMATCH_LIFT_BOOL_ss : bool -> ssfrag

  (* A special case of lifting are function definitions,
     which use PMATCH. In order to use such definitions
     with the rewriting tools, it is often handy to
     move the PMATCH to the toplevel and introduce
     multiple cases, one case for each row of the
     PMATCH. This is automated by the following rules. *)
  val PMATCH_TO_TOP_RULE_GEN : ssfrag list -> rule
  val PMATCH_TO_TOP_RULE : rule

  (********************************)
  (* convert between              *)
  (* case and pmatch              *)
  (********************************)

  (* without proof convert a case to a pmatch expression.
     If the flag is set, optimise the result by
     introducing wildcards reordering rows ... *)
  val case2pmatch : bool -> term -> term

  (* convert a pmatch expression to a case expression.
     Fails, if the pmatch expression uses guards or
     non-constructor patterns. *)
  val pmatch2case : term -> term

  (* The following conversions call
     case2pmatch and pmatch2case and
     afterwards prove the equivalence of
     the result. *)
  val PMATCH_INTRO_CONV : conv
  val PMATCH_INTRO_CONV_NO_OPTIMISE : conv
  val PMATCH_ELIM_CONV : conv


  (*************************************)
  (* Analyse PMATCH expressions to     *)
  (* check whether they can be         *)
  (* translated to ML or OCAML         *)
  (*************************************)

  (* Record storing detailed information about a PMATCH *)
  type pmatch_info = {
    (* Is it a well formed PMATCH, i.e. is it of
       the from PMATCH input row_list, where
       every row is given explicitly via PMATCH_MATCH_ROW
       and is wellformed itself? *)
    pmi_is_well_formed            : bool,

    (* List of all rows that are not well-formed.
       If this list is non-empty, pmi_is_well_formed is false. *)
    pmi_ill_formed_rows           : int list,

    (* List of rows that have guards *)
    pmi_has_guards                : int list,

    (* List of rows that contain variables in a pattern that
       are not bound by the pattern. These free vars are
       returned explicitly. *)
    pmi_has_free_pat_vars         : (int * term list) list,

    (* List of rows whose patterns bind variables that they
       do not use. These unused vars are returned explicitly. *)
    pmi_has_unused_pat_vars       : (int * term list) list,

    (* List of rows whose patterns use a bound variable
       multiple times. These vars are returned explicitly. *)
    pmi_has_double_bound_pat_vars : (int * term list) list,

    (* List of rows that uses constants that are neither
       literals nor datatype-constructors in
       patterns. These constants are returned. *)
    pmi_has_non_contr_in_pat      : (int * term list) list,

    (* List of rows that use lambda-abstractions in patterns. *)
    pmi_has_lambda_in_pat         : int list,

    (* Optional information about exhaustiveness.
       Checking exhaustiveness is expensive, therefore it
       can be skipped. However, if a theorem is stored here,
       it is of the form `|- ~(cond) -> exhaustive`.
       There are no other guarantees. We don't guarantee that
       if the condition holds, the pattern match is inexhaustive.
       This is usually the case, put we don't guarantee it.
       To check, whether the match is exhaustive, check whether
       the guard is T. See below for functions using this
       field.
     *)
    pmi_exhaustiveness_cond       : thm option
  }

  (* Analyse a PMATCH term and return the result. If
     the flag is set to true, an exhaustiveness check is
     attempted, if no syntactic checks indicate that this
     one would most likely fail. *)
  val analyse_pmatch : bool -> term -> pmatch_info

  (* Check whether the PMATCH is syntactically well-formed. *)
  val is_well_formed_pmatch : pmatch_info -> bool

  (* Check whether the PMATCH is falling into the subset
     supported by OCAML *)
  val is_ocaml_pmatch : pmatch_info -> bool

  (* Check whether the PMATCH is falling into the subset
     supported by SML. *)
  val is_sml_pmatch : pmatch_info -> bool;

  (* Was it proved that the PMATCH is exhaustive? If
     the answer is no, we don't know much. *)
  val is_proven_exhaustive_pmatch : pmatch_info -> bool

  (* Get the list of patterns that are possibly missing.
     If no exhaustiveness information is available, NONE
     is returned. The missing patterns are returns as a list
     of triples (`bound-vars`, `pattern`, `guard`) *)
  val get_possibly_missing_patterns : pmatch_info ->
    (term * term * term) list option

  (** extend_possibly_missing_patterns t pmi
      tries to extend the original pattern match t with
      rows derived from the exhaustiveness information
      from its info. It fails, if no exhaustiveness
      information is available. The result should
      be an exhaustive match, which is equivalent to
      the input `t`. If you need a proof, use
      PMATCH_COMPLETE_CONV and similar functions instead
      of this syntactic one. *)
  val extend_possibly_missing_patterns : term -> pmatch_info -> term


  (********************************)
  (* CASE SPLIT (pattern compile) *)
  (********************************)

  (*------------*)
  (* Heuristics *)
  (*------------*)

  (* A column heuristic is used to figure out, in
     which order to process columns. It gets a list of columns
     and returns, which one to pick. *)
  type column_heuristic = (term * (term list * term) list) list -> int

  (* Many heuristics are build on ranking funs.
     A ranking fun assigns an integer to a column. Larger
     numbers are preferred. If two columns have the same
     value, either another ranking fun is used to decide or
     just the first one is used, if no ranking fun is available. *)
  type column_ranking_fun = term * (term list * term) list -> int
  val colHeu_rank : column_ranking_fun list -> column_heuristic

  val colRank_first_row : column_ranking_fun
  val colRank_first_row_constr : constrFamiliesLib.pmatch_compile_db ->
                                 column_ranking_fun
  val colRank_arity : constrFamiliesLib.pmatch_compile_db -> column_ranking_fun
  val colRank_constr_prefix : column_ranking_fun
  val colRank_small_branching_factor : constrFamiliesLib.pmatch_compile_db ->
                                       column_ranking_fun

  (* Some heuristics *)
  val colHeu_first_col : column_heuristic
  val colHeu_last_col : column_heuristic
  val colHeu_first_row : column_heuristic
  val colHeu_constr_prefix : column_heuristic
  val colHeu_cqba : constrFamiliesLib.pmatch_compile_db -> column_heuristic
  val colHeu_qba : constrFamiliesLib.pmatch_compile_db -> column_heuristic

  (* the default heuristic, currently it is
     colHeu_qba applied to the default db. However,
     this might change. You can just rely on a decent heuristic,
     that often works. No specific properties guaranteed. *)
  val colHeu_default : column_heuristic


  (*---------------------*)
  (* PATTERN COMPILATION *)
  (*---------------------*)

  (* [PMATCH_CASE_SPLIT_CONV_GEN ssl db col_heu]
     is a conversion that tries to compile PMATCH expressions
     to decision trees using database [db], column heuristic
     [col_heu] and additional ssfrags [ssl]. *)
  val PMATCH_CASE_SPLIT_CONV_GEN :
     ssfrag list ->
     constrFamiliesLib.pmatch_compile_db ->
     column_heuristic -> conv

  (* A simplified version of PMATCH_CASE_SPLIT_CONV that
     uses the default database and default column heuristic as
     well as no extra ssfrags. *)
  val PMATCH_CASE_SPLIT_CONV : conv

  (* lets choose at least the heuristic *)
  val PMATCH_CASE_SPLIT_CONV_HEU : column_heuristic -> conv

  (* ssfrag corresponding to PMATCH_CASE_SPLIT_CONV_GEN *)
  val PMATCH_CASE_SPLIT_GEN_ss :
     ssfrag list ->
     constrFamiliesLib.pmatch_compile_db ->
     column_heuristic -> ssfrag

  (* ssfrag corresponding to PMATCH_CASE_SPLIT_CONV, since
     it needs to get the current version of the default db,
     it gets a unit argument. *)
  val PMATCH_CASE_SPLIT_ss : unit -> ssfrag

  (* lets choose at least the heuristic *)
  val PMATCH_CASE_SPLIT_HEU_ss : column_heuristic -> ssfrag


  (* Pattern compilation builds for a list of patterns, implicitly
     a nchotomy theorem, i.e. a list of patterns that cover all the
     original ones and are exhaustive. Moreover these patterns usually
     have some nice properties like e.g. not overlapping with each other.
     Such a nchotomy theorem is often handy. We use it to check for
     exhaustiveness for example. The interface
     to compute such an nchotomy is exposed here as well. *)

  (* [nchotomy_of_pats_GEN db colHeu pats] computes an nchotomy-theorem
     for a list of patterns. A pattern is written as for PMATCH, i.e. in the form ``\(v1, ..., vn). p v1 ... vn``. *)
  val nchotomy_of_pats_GEN : constrFamiliesLib.pmatch_compile_db ->
                             column_heuristic -> term list -> thm
  val nchotomy_of_pats : term list -> thm


  (*-----------------------*)
  (* Remove redundant rows *)
  (*-----------------------*)

  (* fancy, slow conversion for detecting and removing
     redundant rows. Internally this uses [nchotomy_of_pats] and
     therefore requires a pmatch-compile db and a column-heuristic. *)
  val PMATCH_REMOVE_REDUNDANT_CONV_GEN :
    constrFamiliesLib.pmatch_compile_db -> column_heuristic -> ssfrag list ->
    conv
  val PMATCH_REMOVE_REDUNDANT_CONV : conv

  val PMATCH_REMOVE_REDUNDANT_GEN_ss :
    constrFamiliesLib.pmatch_compile_db -> column_heuristic -> ssfrag list ->
    ssfrag
  val PMATCH_REMOVE_REDUNDANT_ss : unit -> ssfrag


  (* The redundancy removal conversion works by
     first creating a is-redundant-rows-info theorem and
     then turning it into a PMATCH equation. One can
     separate these steps, this allows using interactive proofs
     for showing that a row is redundant. *)
  val COMPUTE_REDUNDANT_ROWS_INFO_OF_PMATCH_GEN :
    ssfrag list -> constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
    term -> thm
  val COMPUTE_REDUNDANT_ROWS_INFO_OF_PMATCH : term -> thm

  (* Apply the resulting redundant rows-info *)
  val IS_REDUNDANT_ROWS_INFO_TO_PMATCH_EQ_THM : thm -> thm


  (* prove redundancy of given row given an info-thm *)
  val IS_REDUNDANT_ROWS_INFO_SHOW_ROW_IS_REDUNDANT :
    thm -> int -> tactic -> thm

  val IS_REDUNDANT_ROWS_INFO_SHOW_ROW_IS_REDUNDANT_set_goal :
    thm -> int -> proofManagerLib.proofs


  (*-----------------------*)
  (* Exhaustiveness        *)
  (*-----------------------*)

  (* A IS_REDUNDANT_ROW_INFO theorem contains already
     information, whether the pattern match is exhaustive.

     IS_REDUNDANT_ROWS_INFO_TO_PMATCH_IS_EXHAUSTIVE extracts
     this information in the form of an implication. Ideally,
     the precondition is ~F, but the user has to check. *)

  val IS_REDUNDANT_ROWS_INFO_TO_PMATCH_IS_EXHAUSTIVE : thm -> thm

  (* For convenience this is combined with the computation of the
     IS_REDUNDANT_ROWS_INFO. So given a PMATCH term, the following
     functions compute an implication, whose conclusion is the
     exhaustiveness of the PMATCH. *)

  val PMATCH_IS_EXHAUSTIVE_COMPILE_CONSEQ_CHECK : term -> thm
  val PMATCH_IS_EXHAUSTIVE_COMPILE_CONSEQ_CHECK_GEN :
     ssfrag list -> term -> thm
  val PMATCH_IS_EXHAUSTIVE_COMPILE_CONSEQ_CHECK_FULLGEN :
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     (ssfrag list * conv option) -> term -> thm

  (* One can usually even derive an equality.  *)

  val PMATCH_IS_EXHAUSTIVE_COMPILE_CHECK : term -> thm
  val PMATCH_IS_EXHAUSTIVE_COMPILE_CHECK_GEN :
     ssfrag list -> term -> thm
  val PMATCH_IS_EXHAUSTIVE_COMPILE_CHECK_FULLGEN :
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     (ssfrag list * conv option) -> term -> thm


  (* Computing the IS_REDUNDANT_ROWS_INFO takes time and
      is often not necessary. Many pattern matches contain
      for example and catch-all pattern as the last row.
      The following functions try to compute the redundancy
      fast by searching such rows. If they succeed they result
      in a theorem of the form

      EHX_STATEMENT = T

      or

      EHX_STATEMENT = F

      So, this time, there is an equation, not an implication
      and the right-hand-side is always T or F.
   *)
   val PMATCH_IS_EXHAUSTIVE_FAST_CHECK : term -> thm
   val PMATCH_IS_EXHAUSTIVE_FAST_CHECK_GEN : ssfrag list -> term -> thm


   (* Both methods can be combined to combine the speed of
      the fast version with the power of the slow one.

      There are two versions of this, one resulting in an
      equation and one resulting in an implication. The
      equation one is suitable, if one just wants yes/no
      answers, the implicational one to analyse what is missing
      to make the pattern match exhaustive. *)

   val PMATCH_IS_EXHAUSTIVE_CHECK : term -> thm
   val PMATCH_IS_EXHAUSTIVE_CHECK_GEN : ssfrag list -> term -> thm
   val PMATCH_IS_EXHAUSTIVE_CHECK_FULLGEN :
      constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
      (ssfrag list * conv option) -> term -> thm

   val PMATCH_IS_EXHAUSTIVE_CONSEQ_CHECK : term -> thm
   val PMATCH_IS_EXHAUSTIVE_CONSEQ_CHECK_GEN : ssfrag list -> term -> thm
   val PMATCH_IS_EXHAUSTIVE_CONSEQ_CHECK_FULLGEN :
      constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
      (ssfrag list * conv option) -> term -> thm


   (* More interesting than just computing whether a PMATCH
      expression is exhaustive might be adding at the end
      additional rows that explicitly list the missing pats
      and return ARB for them. This is achieved by the following
      functions.

      The additional patterns can use guards or not. If not
      guards are used, the added patterns are more coarse, but
      simpler. *)

   val PMATCH_COMPLETE_CONV : bool -> conv
   val PMATCH_COMPLETE_ss : bool -> ssfrag

   (* and as usual more general versions that allows using
      own pattern compilation settings *)
   val PMATCH_COMPLETE_CONV_GEN : ssfrag list ->
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     bool -> conv

   val PMATCH_COMPLETE_GEN_ss :
     ssfrag list ->
     constrFamiliesLib.pmatch_compile_db ->
     column_heuristic -> bool -> ssfrag


   (* Versions with suffix "WITH_EXH_PROOF" return a theorem stating
      that the resulting case split is exhaustive is returned as well.
      In case the original case split is already exhaustive, no
      conversion theorem is returned. However a theorem stating that the
      original case split is exhaustive is still computed. *)
   val PMATCH_COMPLETE_CONV_WITH_EXH_PROOF : bool -> (term -> (thm option * thm))

   val PMATCH_COMPLETE_CONV_GEN_WITH_EXH_PROOF : ssfrag list ->
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     bool -> (term -> (thm option * thm))

  (*-----------------------*)
  (* Show nchotomy         *)
  (*-----------------------*)

  (* [show_nchotomy t] tries to prove an nchotomy-theorem.
     Given an nchotomy theorem of the form
     ``!x. (?xs1. v = p1 xs1 /\ g1 xs1) \/ ... \/
           (?xsn. v = pn xsn /\ gn xsn)``.
     It returns a theorem that is an implication with
     the input as conclusion. *)
  val SHOW_NCHOTOMY_CONSEQ_CONV : ConseqConv.conseq_conv

  (* A generalised version that allows specifying additional
     parameters. *)
  val SHOW_NCHOTOMY_CONSEQ_CONV_GEN :
    ssfrag list -> constrFamiliesLib.pmatch_compile_db ->
    column_heuristic -> ConseqConv.conseq_conv


  (********************************)
  (* General Lifting              *)
  (********************************)

  (* One can also lift to arbitrary levels. This requires forcing the
     lifted case expression to be exhaustive though.  Therefore,
     PMATCH_COMPLETE_CONV is used internally and a compilation database
     and a column heuristic are needed. Similarly to lifting, there is
     also a version that returns an exhaustiveness statement of the
     result. *)

  val PMATCH_LIFT_CONV : conv

  val PMATCH_LIFT_CONV_GEN : ssfrag list ->
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     conv

  val PMATCH_LIFT_CONV_WITH_EXH_PROOF : term -> (thm * thm)

  val PMATCH_LIFT_CONV_GEN_WITH_EXH_PROOF : ssfrag list ->
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     term -> (thm * thm)


  (********************************)
  (* Flattening                   *)
  (********************************)

  (* Flattening tries to flatten nested PMATCH case expressions into a
     single one. It needs to enforce exhaustiveness. Therefore a
     compilation database and a column heuristic are needed.  The
     additional flag states whether lifting should be attempted.  If
     set to false, only nested PMATCH expressions directly at the top
     of the rhs of a row are considered for flattening. Otherwise,
     lifting is attempted. *)

  val PMATCH_FLATTEN_CONV_GEN : ssfrag list ->
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     bool -> conv

  val PMATCH_FLATTEN_CONV : bool -> conv

  val PMATCH_FLATTEN_GEN_ss : ssfrag list ->
     constrFamiliesLib.pmatch_compile_db -> column_heuristic ->
     bool -> ssfrag

  val PMATCH_FLATTEN_ss : bool -> ssfrag

  (********************************)
  (* eliminating select           *)
  (********************************)

  (* PMATCH leads to selects consisting of
     conjunctions that determine the value of one
     component of the variable. An example is

     @x. SND (SND x = ..) /\ (FST x = ..) /\ (FST (SND x) = ..)

     by resorting these conjunctions, one can
     easily derive a form

     @x. x = ..

     and therefore eliminate the select operator.
     This is done by the following conversion + ssfrag.
     These are used internally by the pattern matches
     infrastructure. *)
  val ELIM_FST_SND_SELECT_CONV : conv
  val elim_fst_snd_select_ss : ssfrag

end
