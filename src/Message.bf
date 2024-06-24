using System;
namespace Phloem;

/// Refcounted message with enum type identification
public class Message<T> : RefCounted where T : enum
{
	public T Type { get; }
	public this(T type) : base() { this.Type = type; }
}