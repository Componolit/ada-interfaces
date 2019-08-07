
with Componolit.Interfaces.Types;
with Componolit.Interfaces.Component;
with Componolit.Interfaces.Block;
with Componolit.Interfaces.Block.Client;
with Componolit.Interfaces.Block.Dispatcher;
with Componolit.Interfaces.Block.Server;

package Component is

   procedure Construct (Cap : Componolit.Interfaces.Types.Capability);
   procedure Destruct;

   package Main is new Componolit.Interfaces.Component (Construct, Destruct);

   type Byte is mod 2 ** 8;
   subtype Unsigned_Long is Long_Integer range 0 .. Long_Integer'Last;
   type Buffer is array (Unsigned_Long range <>) of Byte;
   type Request_Index is mod 8;

   package Block is new Componolit.Interfaces.Block (Byte, Unsigned_Long, Buffer);

   procedure Event;
   procedure Dispatch (C : Block.Dispatcher_Capability);
   procedure Initialize_Server (S : Block.Server_Instance; L : String; B : Block.Byte_Length);
   procedure Finalize_Server (S : Block.Server_Instance);
   function Block_Count (S : Block.Server_Instance) return Block.Count;
   function Block_Size (S : Block.Server_Instance) return Block.Size;
   function Writable (S : Block.Server_Instance) return Boolean;
   function Initialized (S : Block.Server_Instance) return Boolean;

   procedure Write (C :     Block.Client_Instance;
                    I :     Request_Index;
                    D : out Buffer);

   procedure Read (C : Block.Client_Instance;
                   I : Request_Index;
                   D : Buffer);

   package Block_Client is new Block.Client (Request_Index, Event, Read, Write);
   package Block_Server is new Block.Server (Event,
                                             Block_Count,
                                             Block_Size,
                                             Writable,
                                             Initialized,
                                             Initialize_Server,
                                             Finalize_Server);
   package Block_Dispatcher is new Block.Dispatcher (Block_Server, Dispatch);

end Component;
