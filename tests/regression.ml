open X509

let cs_mmap file =
  Unix_cstruct.of_fd Unix.(openfile file [O_RDONLY] 0)

let cert file =
  let data = cs_mmap ("./regression/" ^ file ^ ".pem") in
  match Encoding.Pem.Certificate.of_pem_cstruct1 data with
  | Ok cert -> cert
  | Error m -> Alcotest.failf "certificate decoding error %a" Encoding.pp_err m

let jc = cert "jabber.ccc.de"
let cacert = cert "cacert"

let test_jc_jc () =
  match Validation.verify_chain_of_trust ~host:(`Strict "jabber.ccc.de") ~anchors:[jc] [jc] with
  | Error `InvalidChain -> ()
  | _ -> Alcotest.fail "something went wrong with jc_jc"

let test_jc_ca () =
  match Validation.verify_chain_of_trust ~host:(`Strict "jabber.ccc.de") ~anchors:[cacert] [jc ; cacert] with
  | Ok _ -> ()
  | _ -> Alcotest.fail "something went wrong with jc_ca"

let telesec = cert "telesec"
let jfd = [ cert "jabber.fu-berlin.de" ; cert "fu-berlin" ; cert "dfn" ]

let test_jfd_ca () =
  match Validation.verify_chain_of_trust ~host:(`Strict "jabber.fu-berlin.de") ~anchors:[telesec] (jfd@[telesec]) with
  | Ok _ -> ()
  | _ -> Alcotest.fail "something went wrong with jfd_ca"

let test_jfd_ca' () =
  match Validation.verify_chain_of_trust ~host:(`Strict "jabber.fu-berlin.de") ~anchors:[telesec] jfd with
  | Ok _ -> ()
  | _ -> Alcotest.fail "something went wrong with jfd_ca'"

let regression_tests = [
  "RSA: key too small (jc_jc)", `Quick, test_jc_jc ;
  "jc_ca", `Quick, test_jc_ca ;
  "jfd_ca", `Quick, test_jfd_ca ;
  "jfd_ca'", `Quick, test_jfd_ca'
]
