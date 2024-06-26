# Pull EBS CSI IAM POLICY
data "http" "ebs_csi_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/docs/example-iam-policy.json"

  request_headers = {
    Accept = "application/json"
  }
}

// Create the IAM Policy
resource "aws_iam_policy" "ebs_csi_iam_policy" {
  name        = "${var.name}-AmazonEKS_EBS_CSI_Driver_Policy"
  path        = "/"
  description = "EBS CSI IAM Policy"
  policy      = data.http.ebs_csi_iam_policy.response_body
}

resource "aws_iam_role" "ebs_csi_iam_role" {
  name = "${var.name}-ebs-csi-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${var.oidc_arn}"
        }
        Condition = {
          StringEquals = {
            "${var.oidc_extracted_arn}:sub" : "system:serviceaccount:${kubernetes_namespace_v1.block_storage.metadata[0].name}:ebs-csi-controller-sa"
          }
        }

      },
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.ebs_csi_iam_policy.arn
  role       = aws_iam_role.ebs_csi_iam_role.name
}

output "ebs_csi_iam_role_arn" {
  description = "EBS CSI IAM Role ARN"
  value       = aws_iam_role.ebs_csi_iam_role.arn
}


