import ../src/nimnbt, ../src/nimnbt/[parse, convert, builder]

# Parse example
let parsedTag = parseNbtFile("hello_world.nbt")

# Builder example
let tag = TAG_Compound("hello world", @[
    TAG_String("name", "Bananrama")
])

# Convert example
let convertedTag = tag.toNbt()

# Other
assert parsedTag.toNbt() == convertedTag

echo $parsedTag
echo $parsedTag.name
echo $tag["name"]