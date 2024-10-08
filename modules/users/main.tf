resource "aws_iam_user" "ecs_deployer" {
  name = "food_ecs_deployer"
  path = "/ecs/"
}

# The most important part is the iam:PassRole. With that, this user can give roles to ECS tasks.
# In theory the user can give the task Admin rights. To make sure that does not happen we restrict
# the user and allow him only to hand out roles in /ecs/ path. You still need to be careful not
# to have any roles in there with full admin rights, but no ECS task should have these rights!
resource "aws_iam_user_policy" "ecs_deployer_policy" {
  name = "food_ecs_deployer_policy"
  user = aws_iam_user.ecs_deployer.name

  policy = "${file("ecs_deployer.json")}"
}

resource "aws_iam_access_key" "ecs_deployer" {
  user = aws_iam_user.ecs_deployer.name
}
