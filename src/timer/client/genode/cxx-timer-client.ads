
with System;
with Gneiss.Types;

package Cxx.Timer.Client is

   type Class is limited record
      Session : Cxx.Void_Address;
   end record
   with Import, Convention => CPP;

   function Constructor return Class with
      Global => null;
   pragma Cpp_Constructor (Constructor, "_ZN3Cai5Timer6ClientC1Ev");

   function Initialized (This : Class) return Cxx.Bool with
      Global        => null,
      Import,
      Convention    => CPP,
      External_Name => "_ZN3Cai5Timer6Client11initializedEv";

   procedure Initialize (This : Class;
                         Cap  : Gneiss.Types.Capability;
                         Ev   : System.Address) with
      Global        => null,
      Import,
      Convention    => CPP,
      External_Name => "_ZN3Cai5Timer6Client10initializeEPvS2_";

   function Clock (This : Class) return Duration with
      Global        => null,
      Import,
      Convention    => CPP,
      External_Name => "_ZN3Cai5Timer6Client5clockEv";

   procedure Set_Timeout (This : Class;
                          Dur  : Duration) with
      Global        => null,
      Import,
      Convention    => CPP,
      External_Name => "_ZN3Cai5Timer6Client11set_timeoutEy";

   procedure Finalize (This : Class) with
      Global        => null,
      Import,
      Convention    => CPP,
      External_Name => "_ZN3Cai5Timer6Client8finalizeEv";

end Cxx.Timer.Client;
