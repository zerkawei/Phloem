# Phloem

Phloem is a basic messaging library for the [Beef programming language](https://github.com/beefytech/Beef).

## Listener & Messages

Messages are reference counted in Phloem and use an enum to type messages. Listeners can be bound to a channel and provide a `Next` method to get the next available message or `.Err` and an enumerator over the available messages. The enumerator keeps a reference of the current message and release the reference when moving to the next message.

```csharp
for(let msg in listener)
{
    switch(msg.Type)
    {
        ...
    }
}
```

## QueueChannel

The `QueueChannel` is a simple queue for messages where a message is read by only a single listener.

```csharp
let qChannel = scope QueueChannel<MsgType>();

qChannel.Post(new .(.Log)); // Message is queued

let qList1 = scope Listener<MsgType>(qChannel);
let qList2 = scope Listener<MsgType>(qChannel);

qChannel.Post(new .(.Error));

qList1.Next() // .Log
qList2.Next() // .Error

qChannel.Post(new .(.Warning));

qList1.Next() // .Warning
```

## BroadcastChannel

The `BroadcastChannel` allows for a single message to be read by many listeners. Every listener has its own head into the queue and joins at the tail of the queue. When a listener is the last to read a message the message is removed from the queue. A broadcast listener can also define a filter to only recieve certain messages.

```csharp
public enum MsgType
{
    Log,
    Warning,
    Error
}

let bChannel = scope BroadcastChannel<MsgType>();

bChannel.Post(new .(.Log)); // Message dropped because the channel has no listeners

let bList1 = scope BroadcastListener<MsgType>(bChannel);
let bList2 = scope BroadcastListener<MsgType>(bChannel, new TypeSetFilter<MsgType>(.Error)); // Only recieve .Error messages

bChannel.Post(new .(.Log));
bChannel.Post(new .(.Error));

let bList3 = scope BroadcastListener<MsgType>(bChannel);

bChannel.Post(new .(.Warning));

// bList1 has the following messages : .Log, .Error, .Warning
// bList2 has the following messages : .Error
// bList3 has the following messages : .Warning
```