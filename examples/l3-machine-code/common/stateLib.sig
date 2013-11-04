signature stateLib =
sig
   include Abbrev

   type footprint_extra = (term * term) * (term -> term) * (term -> term)
   val define_map_component: string * string * thm -> thm * thm
   val dest_code_access: term -> int * term
   val fix_precond: thm list -> thm list
   val generate_temporal: unit -> bool
   val get_delta: term -> term -> int option
   val get_pc_delta: (term -> bool) -> thm -> int option
   val group_into_chunks:
      (term -> term * term) * int * (term -> term) -> bool * term list ->
         {redex: term, residue: term} list list *
         ({redex: term, residue: term} list * (term * term) list)
   val gvar: string -> hol_type -> term
   val introduce_triple_definition: bool * thm -> rule
   val introduce_map_definition: thm * conv -> rule
   val is_code_access: string * term -> term -> bool
   val list_mk_code_pool: term * term * term list -> term
   val mk_code_pool: term * term * term -> term
   val mk_pre_post:
      thm -> thm list -> (thm -> term * term * term) -> footprint_extra list ->
      (term list * term list * term -> term list * term list) ->
      (term list -> term list) ->
      thm -> term
   val pool_select_state_thm: thm -> thm list -> thm -> thm
   val read_footprint:
      thm -> thm list -> (thm -> term * term * term) -> footprint_extra list ->
      thm -> term list * term * term * term
   val rename_vars:
      (string -> string option) * (string -> (term -> string) option) *
      string list -> thm -> thm
   val sep_array_intro:
      (term -> term) -> (term -> bool) -> thm -> thm list -> rule
   val sep_definitions:
      string -> string list list -> string list list -> thm -> thm list
   val set_temporal: bool -> unit
   val spec:
      thm -> thm -> thm list -> thm list -> thm list -> thm list -> thm list ->
      hol_type list -> tactic -> tactic -> thm * term -> thm
   val star_select_state_thm: thm -> thm list -> term list * thm -> thm
   val update_frame_state_thm:
      thm -> (Q.tmquote * Q.tmquote * Q.tmquote) list -> thm
   val update_hidden_frame_state_thm: thm -> term list -> thm
   val vvar: hol_type -> term
   val varReset: unit -> unit
   val write_footprint:
     (string -> term * (term -> term) * (term -> term) * (term -> bool)) ->
     (string -> term * (term * term -> term) * (term -> term * term) *
      (term -> bool)) ->
     (string * string * term) list ->
     (string * string) list ->
     (string * string) list ->
     (string * (term list * term list * term -> term list * term list)) list ->
     (string * term list -> bool) ->
     term list * term list * term -> term list * term list
   val MOVE_COND_CONV: conv
   val PC_CONV: string -> conv
end
