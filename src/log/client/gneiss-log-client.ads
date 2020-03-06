--
--  @summary Log client interface
--  @author  Johannes Kliemann
--  @date    2019-04-10
--
--  Copyright (C) 2019 Componolit GmbH
--
--  This file is part of Gneiss, which is distributed under the terms of the
--  GNU Affero General Public License version 3.
--

package Gneiss.Log.Client with
   SPARK_Mode
is

   --  Intialize client
   --
   --  @param Session Client session instance
   --  @param Cap     System capability
   --  @param Label   Session label
   --  @param Idx     Session index
   procedure Initialize (Session : in out Client_Session;
                         Cap     :        Capability;
                         Label   :        String);

   --  Finalize client session
   --
   --  @param Session  Client session instance
   procedure Finalize (Session : in out Client_Session) with
      Post => not Initialized (Session);

   --  Print unformatted message
   --
   --  @param Session  Client session instance
   --  @param Msg      Message to print
   procedure Print (Session : in out Client_Session;
                    Msg     :        String) with
      Pre  => Initialized (Session),
      Post => Initialized (Session);

   --  Print info message
   --
   --  @param Session        Client session instance
   --  @param Msg      Message to print
   --  @param Newline  Append a newline to the message
   procedure Info (Session : in out Client_Session;
                   Msg     :        String;
                   Newline :        Boolean := True) with
      Pre  => Initialized (Session),
      Post => Initialized (Session);

   --  Print warning message
   --
   --  @param Session        Client session instance
   --  @param Msg      Message to print
   --  @param Newline  Append a newline to the message
   procedure Warning (Session : in out Client_Session;
                      Msg     :        String;
                      Newline :        Boolean := True) with
      Pre  => Initialized (Session),
      Post => Initialized (Session);

   --  Print error message
   --
   --  @param Session        Client session instance
   --  @param Msg      Message to print
   --  @param Newline  Append a newline to the message
   procedure Error (Session : in out Client_Session;
                    Msg     :        String;
                    Newline :        Boolean := True) with
      Pre  => Initialized (Session),
      Post => Initialized (Session);

   --  Flush all messages to make sure they're printed
   --
   --  @param Session        Client session instance
   procedure Flush (Session : in out Client_Session) with
      Pre  => Initialized (Session),
      Post => Initialized (Session);

end Gneiss.Log.Client;
