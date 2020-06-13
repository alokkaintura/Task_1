provider "aws" {
  region                  = "ap-south-1"
  profile                 = "alokpro"
}


resource "tls_private_key" "web_key" {
  algorithm   = "RSA"
  rsa_bits = 4096
}


resource "local_file" "web_gen" {
    filename = "my_key.pem"
}


resource "aws_key_pair" "web_key" {
  key_name   = "my_key"
  public_key = tls_private_key.web_key.public_key_openssh  
}


resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro" 
  security_groups = [ "mysg-1" ]  
  key_name      = aws_key_pair.web_key.key_name

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.web_key.private_key_pem
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

tags = {
    Name = "Mr.India"
  }
}


output  "myvol1" {
	value = aws_instance.web.availability_zone
}
 

resource "aws_security_group" "mysg-1" {
  name        = "mysg-1"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-ffe5f897"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysg-1"
  }
}


resource "aws_ebs_volume" "ebs12" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1

  tags = {
    Name = "myvolume"
  }
}


resource "aws_volume_attachment" "ebsattch" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ebs12.id
  instance_id = aws_instance.web.id
  force_detach = true
}


resource "null_resource" "lnul_12"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.web.public_ip} > mypublicip.txt"
  	}
}


resource "null_resource" "localnul12"  {
depends_on = [
      aws_volume_attachment.ebsattch,
    ]

	connection {
                   type     = "ssh"
                   user     = "ec2-user"
                   private_key = tls_private_key.web_key.private_key_pem
                   host     = aws_instance.web.public_ip
              }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/11kush11410/alok.git /var/www/html/"
    ]
  }
 }



resource "aws_s3_bucket" "bonzovi999" {
  bucket = "bonzovi999"
  acl     = "public-read"

 provisioner "local-exec" {
        command     = "git clone https://github.com/11kush11410/alok new_folder"
    }
 provisioner "local-exec" {
        when        =   destroy
        command     =   "echo Y | rmdir /s new_folder"
    }
}


resource "aws_s3_bucket_object"  "jupiter8844" {

    bucket  = aws_s3_bucket.bonzovi999.bucket
    key     = "himanshu.jpg"
    source  = "new_folder/asdf.jpg"
    acl     = "public-read"
}


locals {
  s3_origin_id = aws_s3_bucket.bonzovi999.bucket
  image_url = "${aws_cloudfront_distribution.distribution.domain_name}/${aws_s3_bucket_object.jupiter8844.key}"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.bonzovi999.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E3J4B4GW64GHQS"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "myfile.php"


default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 99999
  }

restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

viewer_certificate {
    cloudfront_default_certificate = true
  }



connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.web_key.private_key_pem 
    host     = aws_instance.web.public_ip
  }

provisioner "remote-exec" {
        inline  = [
            "sudo su << EOF",
            "echo \"<img src='http://${self.domain_name}/${aws_s3_bucket_object.jupiter8844.key}'>\" >> /var/www/html/index.php",
            "EOF"
        ]
    }

}


resource "null_resource" "local-null"  {
    depends_on = [
    aws_cloudfront_distribution.distribution,
   ]

    provisioner "local-exec" {
        command = "start chrome  ${aws_instance.web.public_ip}"
      }
 }




