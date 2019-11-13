--
--  @summary Timer interface
--  @author  Johannes Kliemann
--  @date    2019-04-10
--
--  Copyright (C) 2019 Componolit GmbH
--
--  This file is part of Gneiss, which is distributed under the terms of the
--  GNU Affero General Public License version 3.
--

private with Componolit.Gneiss.Internal.Timer;

package Componolit.Gneiss.Timer with
   SPARK_Mode
is

   --  Duration compatible time type
   type Time is new Duration;

   --  "+" operator for Time and Duration
   --
   --  @param Left   Time
   --  @param Right  Time difference
   --  @return       Time
   function "+" (Left : Time; Right : Duration) return Time is
      (Left + Time (Right)) with
      Pre => (if Right > 0.0 then Left < Time'Last - Time (Right))
             and (if Right < 0.0 then Left > Time'First - Time (Right));

   --  "-" operator for Time and Duration
   --
   --  @param Left   Time
   --  @param Right  Time difference
   --  @return       Time
   function "-" (Left : Time; Right : Duration) return Time is
      (Time (Left - Time (Right))) with
      Pre => (if Right > 0.0 then Left > Time'First + Time (Right))
             and (if Right < 0.0 then Left < Time'Last + Time (Right));

   --  Timer client session object
   type Client_Session is limited private;

   --  Checks if session is initialized
   --
   --  @param C  Timer client session object
   --  @return   True if session is initialized else False
   function Initialized (C : Client_Session) return Boolean;

private

   type Client_Session is new Componolit.Gneiss.Internal.Timer.Client_Session;

end Componolit.Gneiss.Timer;
