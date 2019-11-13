--
--  @summary Rom interface
--  @author  Johannes Kliemann
--  @date    2019-04-10
--
--  Copyright (C) 2019 Componolit GmbH
--
--  This file is part of Gneiss, which is distributed under the terms of the
--  GNU Affero General Public License version 3.
--

private with Componolit.Gneiss.Internal.Rom;

package Componolit.Gneiss.Rom with
   SPARK_Mode
is

   type Client_Session is limited private;

   function Initialized (C : Client_Session) return Boolean;

private

   type Client_Session is new Componolit.Gneiss.Internal.Rom.Client_Session;

end Componolit.Gneiss.Rom;
