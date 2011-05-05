open Ocsigen_senders
open Ocsigen_extensions

let fun_site virtual_hosts config_info url_path parse_host parse_fun xml req =
  Ocsigen_messages.warning "extension accessed" ; 
  Lwt.return (Ext_found_stop (fun () -> Text_content.result_of_content ("Extension answer", "text/plain")))

let () = register_extension ~fun_site ~user_fun_site:(fun _ -> fun_site) ~name:"extension" ()

let () = Ocsigen_messages.warning "extension loaded"
