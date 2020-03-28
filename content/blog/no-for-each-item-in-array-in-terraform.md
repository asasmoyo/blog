---
title: "No for Each Item in Array in Terraform"
date: 2020-03-28T17:15:23+07:00
draft: true
---

I was importing my team's PagerDuty setup into Terraform today. There are 6 people in PagerDuty users so I thought, I would create locals block with users as array of map containing each name and email. Then I'd feed `local.users` into `pagerduty_user` resource using `for_each`.

``` hcl
locals {
    users = [
        {
            name = "John Doe"
            email = "john@company.com"
        },
        {
            name = "Somebody"
            email = "somebody@company.com"
        },
        // ...
    ]
}

resource "pagerduty_user" "users" {
    for_each = local.users

    name = each.value.name
    email = each.value.email
}
```

It turned out, `for_each` doesn't accept array, it only accepts map or set. So above code didn't work but it has to be like bellow:

``` hcl
locals {
    users = [
        john = {
            name = "John Doe"
            email = "john@company.com"
        },
        somebody = {
            name = "Somebody"
            email = "somebody@company.com"
        },
        // ...
    ]
}

resource "pagerduty_user" "users" {
    for_each = local.users

    name = each.value.name
    email = each.value.email
}
```

But why wouldn't it accept array? If I think about it again, it's for a good reason. Let me explain.

Suppose `for_each` works with array, what would happen if at some point in the future, you remove one item in the middle of the array? Your resources from that removed index until the end will be shifted forward and neds to be recreated by Terraform. Don't forget that Terraform use index for array resources. So for `pagerduty_user` resource, there will be `pagerduty_user[0]`, `pagerduty_user[1]`, `pagerduty_user[2]` and soon.

It may be fine for resources like `pagerduty_user`, but what would happen if you used on machines with your database in it? And with no backup configured. Yes that could be disaster.
