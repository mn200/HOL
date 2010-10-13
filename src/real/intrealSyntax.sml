structure intrealSyntax :> intrealSyntax =
struct

  local open intrealTheory in end

  open Abbrev intSyntax realSyntax

  val ERR = mk_HOL_ERR "intrealSyntax"

  (* Fundamental terms *)

  fun mk_const (n, ty) = mk_thy_const {Thy = "intreal", Name = n, Ty = ty}

  val real_of_int_tm = mk_const ("real_of_int", int_ty --> real_ty)
  val INT_FLOOR_tm = mk_const ("INT_FLOOR", real_ty --> int_ty)
  val INT_CEILING_tm = mk_const ("INT_CEILING", real_ty --> int_ty)
  val is_int_tm = mk_const ("is_int", real_ty --> bool)

  (* Functions *)

  fun dest1 c fnm nm t =
  let
    val (f, x) = dest_comb t
    val _ = assert (same_const f) c
  in
    x
  end handle HOL_ERR _ => raise ERR fnm ("Term is not an " ^ nm)

  val dest_real_of_int = dest1 real_of_int_tm "dest_real_of_int" "injection"
  val is_real_of_int = Lib.can dest_real_of_int
  fun mk_real_of_int t = Term.mk_comb (real_of_int, t)

  val dest_INT_FLOOR = dest1 INT_FLOOR_tm "dest_INT_FLOOR" "integer floor"
  val is_INT_FLOOR = Lib.can dest_INT_FLOOR
  fun mk_INT_FLOOR t = Term.mk_comb (INT_FLOOR, t)

  val dest_INT_CEILING = dest1 INT_CEILING_tm "dest_INT_CEILING" "integer ceiling"
  val is_INT_CEILING = Lib.can dest_INT_CEILING
  fun mk_INT_CEILING t = Term.mk_comb (INT_CEILING, t)

  val dest_is_int = dest1 is_int_tm "dest_is_int" "is_int test"
  val is_is_int = Lib.can dest_is_int
  fun mk_is_int t = Term.mk_comb (is_int, t)

end
