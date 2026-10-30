class_name ConditionDef
extends Resource
## One condition of a ReactionRecipe.

enum Kind { CHANNEL_AT_LEAST, CHANNEL_AT_MOST, HAS_TAG, HAS_STATE }
enum Scope { SELF, NEIGHBOR_ANY }

@export var kind: int = Kind.CHANNEL_AT_LEAST
@export var channel: int = Channels.Channel.HEAT
@export var threshold: int = 0
@export var tag: StringName = &""
@export var state_name: StringName = &""
@export var scope: int = Scope.SELF


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if kind < Kind.CHANNEL_AT_LEAST or kind > Kind.HAS_STATE:
		errors.append("CONDITION_KIND_INVALID: %d" % kind)
	if scope != Scope.SELF and scope != Scope.NEIGHBOR_ANY:
		errors.append("CONDITION_SCOPE_INVALID: %d" % scope)
	if (kind == Kind.CHANNEL_AT_LEAST or kind == Kind.CHANNEL_AT_MOST) and not Channels.is_valid(channel):
		errors.append("CONDITION_CHANNEL_INVALID: %d" % channel)
	if kind == Kind.HAS_TAG and tag == &"":
		errors.append("CONDITION_TAG_EMPTY")
	if kind == Kind.HAS_STATE and state_name == &"":
		errors.append("CONDITION_STATE_EMPTY")
	if threshold < 0 or threshold > Channels.MAX_VALUE:
		errors.append("CONDITION_THRESHOLD_INVALID: %d" % threshold)
	return errors
