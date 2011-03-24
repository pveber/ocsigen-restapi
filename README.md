Attempt to write an extension to ocsigen web server that serves RESTful-like APIs. A REST API is implemented with two functions:

* a function to check a login/password
* a function that handles the incoming requests, with a simple pattern matching. 

Here is a very basic usage:



    let check_login login passwd = login = passwd

    let serve = function 
      | _,_,_,None -> Restapi.error_content 401
      | `GET params, path, _, Some user ->
          Text_content.result_of_content (
	    (String.concat "/" path) ^ "\n" ^ 
	    user ^ "\n", "text/plain") 
      | `POST (get_params, post_params),_,_,_ ->
          Text_content.result_of_content (
            "POST\n" ^ 
	    (String.concat " " (List.map snd get_params)) ^ "\n" ^ 
	    (String.concat " " (List.map snd post_params)),
	    "text/plain")
      | `PUT (get_params, post_params),_,_,_ ->
          Text_content.result_of_content (
          	"PUT\n" ^ 
		(String.concat " " (List.map snd get_params)) ^ "\n" ^ 
		(String.concat " " (List.map snd post_params)),
        	"text/plain")
      | _ -> Restapi.error_content 404


    let () = register_service [ "api" ] check_login serve
