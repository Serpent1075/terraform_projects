module custom7549 {
   source = "./lbmodule" 
 	alb_arn = aws_lb.webapi_alb.arn
 	vpc_id = var.vpc_id
 	app_port = 7549
 	acm_arn = var.acm_arn
 	prefix = var.prefix
 	sufix = var.sufix
}

module custom7550 {
   source = "./lbmodule" 
 	alb_arn = aws_lb.webapi_alb.arn
 	vpc_id = var.vpc_id
 	app_port = 7550
 	acm_arn = var.acm_arn
 	prefix = var.prefix
 	sufix = var.sufix
}