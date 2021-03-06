(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

open Lwt

(* Mirage transport for XenStore. *)
module IO = struct
    type 'a t = 'a Lwt.t
    type channel = {
      mutable page: Cstruct.t;
      mutable evtchn: Eventchn.t;
    }
    let return = Lwt.return
    let (>>=) = Lwt.bind
    exception Already_connected
    exception Cannot_destroy

    let h = Eventchn.init ()

    type backend = [ `unix | `xen ]
    let backend = `xen

    let create () =
      let page = Io_page.to_cstruct Start_info.(xenstore_start_page ()) in
      Xenstore_ring.Ring.init page;
      let evtchn = Eventchn.of_int Start_info.((get ()).store_evtchn) in
      return { page; evtchn }

    let destroy t =
      Console.log "ERROR: It's not possible to destroy the default xenstore connection";
      fail Cannot_destroy

    (* XXX: unify with ocaml-xenstore-xen/xen/lib/xs_transport_domain *)
    let rec read t buf ofs len =
      let n = Xenstore_ring.Ring.Front.unsafe_read t.page buf ofs len in
      if n = 0 then begin
        lwt () = Activations.wait t.evtchn in
        read t buf ofs len
      end else begin
        Eventchn.notify h t.evtchn;
        return n
      end

    (* XXX: unify with ocaml-xenstore-xen/xen/lib/xs_transport_domain *)
    let rec write t buf ofs len =
      let n = Xenstore_ring.Ring.Front.unsafe_write t.page buf ofs len in
      if n > 0 then Eventchn.notify h t.evtchn;
      if n < len then begin
        lwt () = Activations.wait t.evtchn in
        write t buf (ofs + n) (len - n)
      end else return ()
end

include Xs_client_lwt.Client(IO)

