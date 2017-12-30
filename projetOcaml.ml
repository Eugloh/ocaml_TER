(*load the library and open the appropriate modules*)
#require "bistro.bioinfo bistro.utils"
open Bistro.EDSL
open Bistro_bioinfo.Std
open Bistro_utils
(*Parameter descr: description of the workflow, used for logging*) 

let touch =
  workflow ~descr:"touch" [
    cmd "touch" [ dest ] ;
  ]

let env = docker_image ~account:"pveber" ~name:"kissplice" ~tag:"2.4.0" ()

let fichier= input "./SknshRACellRep1_10M.fastq" 
let fichier2= input "./SknshRACellRep2_10M.fastq" 
let fichier3= input "./SknshCellRep3_10M.fastq" 
let fichier4= input "./SknshCellRep4_10M.fastq" 

(*val dep : _ Workflow.t ‑> t
dep w is interpreted as the path where to find the result of workflow w*) 


let kissplice fqs =
  let link_names =
    List.mapi 
      (fun i _ -> tmp // (Printf.sprintf "reads%d.fq" i))
      fqs in
  let link_cmds =
    List.map2
      (fun fq link  ->
         cmd "ln" [string "-s" ; dep fq ; link])
      fqs link_names in
  let r_args = 
    List.map 
      (fun link -> opt "-r" (fun x -> x) link) 
      link_names in
  let kissplice_cmd = 
    cmd "kissplice" (r_args @ [
      opt "-o" (fun x -> x) dest ;
    ]) in
  let cmds = [ mkdir_p tmp ] @ link_cmds @ [ kissplice_cmd ] in
  workflow ~descr: "kissplice" [
        docker env (and_list cmds)
    ]




(*we specify which output we are interested in*) 

let repo = Repo.[
             [ "touch" ] %> touch ;
             [ "kissplice" ] %> kissplice [fichier;fichier2;fichier3;fichier4];
           ]
(*run the workflow using a function from the Repo module*)

let logger = 
  Html_logger.create "report.html"

let () = Repo.build ~outdir:"res" ~np:2 ~mem:(`GB 4) ~logger repo
