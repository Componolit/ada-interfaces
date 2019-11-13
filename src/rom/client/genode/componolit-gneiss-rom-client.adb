
with System;
with Cxx;
with Cxx.Genode;
with Cxx.Configuration.Client;

package body Componolit.Gneiss.Rom.Client
is

   procedure C_Parse (Ptr : System.Address;
                      Len : Cxx.Genode.Uint64_T);

   procedure Initialize (C    : in out Client_Session;
                         Cap  :        Componolit.Gneiss.Types.Capability;
                         Name :        String := "") with
      SPARK_Mode => Off
   is
      C_Name : constant String := (if Name'Length > 0 then Name else "config") & Character'First;
   begin
      if Initialized (C) then
         return;
      end if;
      Cxx.Configuration.Client.Initialize (C.Instance, Cap, C_Parse'Address, C_Name'Address);
   end Initialize;

   procedure Load (C : in out Client_Session)
   is
   begin
      Cxx.Configuration.Client.Load (C.Instance);
   end Load;

   procedure Finalize (C : in out Client_Session)
   is
   begin
      if not Initialized (C) then
         return;
      end if;
      Cxx.Configuration.Client.Finalize (C.Instance);
   end Finalize;

   procedure C_Parse (Ptr : System.Address;
                      Len : Cxx.Genode.Uint64_T)
   is
      use type System.Address;
      use type Cxx.Genode.Uint64_T;
      Empty : Buffer (1 .. 0);
      Elen  : constant Cxx.Genode.Uint64_T := Len / (Element'Size / 8);
   begin
      if
         Ptr /= System.Null_Address
         and Elen > 0
         and Cxx.Genode.Uint64_T (Index'Last) > Cxx.Genode.Uint64_T (Index'First) + Elen
      then
         declare
            Data : Buffer (Index'First .. Index'First + Index (Elen) - 1) with
               Address => Ptr;
         begin
            Parse (Data);
         end;
      else
         Parse (Empty);
      end if;
   end C_Parse;

end Componolit.Gneiss.Rom.Client;
