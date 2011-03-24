open Ocsigen_extensions
open Ocsigen_messages
open Ocsigen_http_frame.Http_header
open Ocsigen_senders

exception Failed_authentication

type service = method_call * path * content_type * identification -> Ocsigen_http_frame.result Lwt.t
and path = string list
and identification = string option
and method_call = [
  `GET  of arguments
| `POST of arguments * arguments
| `PUT  of arguments * arguments
]
and arguments = (string * string) list
and content_type = ((string * string) * (string * string) list) option

let credentials ri = 
  try 
    let credentials =
      Http_headers.find
	(Http_headers.name "Authorization")
	ri.request_info.ri_http_frame.Ocsigen_http_frame.frame_header.Ocsigen_http_frame.Http_header.headers in
    let n = String.length credentials in
    if n > 6 && String.sub credentials 0 6 = "Basic " then 
      let encoded = String.sub credentials 6 (n-6) in
      let decoded = Netencoding.Base64.decode encoded in
      let i = String.index decoded ':' in
      Some (
	String.sub decoded 0 i,
	String.sub decoded (i+1) (String.length decoded - (i+1)))
    else None
  with Not_found -> None

let get_params_of_req req = Lazy.force req.request_info.ri_get_params

let post_params_of_req req =req.request_info.ri_post_params req.request_config 
      

let method_call req = match req.request_info.ri_method with
  | GET -> Lwt.return (`GET (get_params_of_req req))
  | POST -> 
      lwt post_params = post_params_of_req req in
      Lwt.return (`POST (get_params_of_req req, post_params))
  | PUT -> 
      lwt post_params = post_params_of_req req in
      Lwt.return (`PUT (get_params_of_req req, post_params))

  | _ -> assert false
  
let error_content code = 
  Error_content.result_of_content (Some code,None,Ocsigen_cookies.Cookies.empty)

let login_of_req check_password req = 
  match credentials req with 
      Some (login, password) ->
	if check_password login password 
	then Lwt.return (Some login) 
	else raise_lwt Failed_authentication
    | None -> Lwt.return None

let main check_password service req () = 
  try_lwt
    lwt meth = method_call req in
    lwt login = login_of_req check_password req in
    service (meth, 
	     req.request_info.ri_sub_path, 
	     req.request_info.ri_content_type,
	     login)
  with 
      Failed_authentication -> error_content 401
    
let rec prefix u v = match u, v with
    [], _ -> true
  | h_u :: t_u, h_v :: t_v when h_u = h_v ->
      prefix t_u t_v
  | _ -> false
      

let register : (path * (string -> string -> bool) * service) list ref = ref []

let is_served path = 
  List.exists (fun (hook,_,_) -> prefix hook path) !register

let find_service path = 
  List.find (fun (hook,_,_) -> prefix hook path) !register

let register_service path check_login service = 
  register := (path,check_login,service) :: !register

let fun_site virtual_hosts config_info url_path parse_host parse_fun xml = function
    Req_not_found (_,req) when is_served req.request_info.ri_sub_path -> 
      let _, auth, serve = find_service req.request_info.ri_sub_path in
      Lwt.return (Ext_found (main auth serve req))
  | _ -> Lwt.return Ext_do_nothing



let () = register_extension ~fun_site ~name:"restapi" ()







