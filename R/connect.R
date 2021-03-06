#' @title Block diagram interconnections of dynamic systems
#'
#' @description
#' \code{connect} is used to form a state-space model of a system from its block diagram.
#'
#' @details
#'  \code{connect}
#'  This function requires calling the \code{\link{append}} function to group a set of unconnected dynamics system
#'  in one system object. It then uses the \code{q} matrix to determine the interconnections between the systems
#'  and finally specifies the inputs and outputs for the new aggregate system.
#'  This approach helps to realize a block diagram as a single system on which further analysis could be performed.
#'  See examples below.
#'
#' @param sysapp A state-space system containing several appended systems returned from the \code{\link{append}} function.
#'               All appended systems must be in state-space model.
#' @param q      Matrix that specifies the interconnections of the block diagram. Each row specifies a connection.
#'               The first element of each row is the number of the block. The other following elements of each row specify where the  block gets its summing inputs, with negative elements used to
#'               indicate minus inputs to the summing junction.
#'               For example: cbind(2,1,3) means that block 2 has an input from block 1 and block 3
#' @param inputs A column matrix specifying the inputs of the resulting aggregate system
#' @param outputs A column matrix specifying the outputs of the resulting aggregate system
#'
#' @return Returns the interconnected system, returned as either a state-space model
#'
#' @seealso \code{\link{append}} \code{\link{series}} \code{\link{parallel}} \code{\link{feedback}}
#'
#' @examples
#' a1 <- rbind(c(0, 0), c(1,-3))
#' b1 <- rbind(-2,0)
#' c1 <- cbind(0,-1)
#' d <- as.matrix(0)
#' a2 <- as.matrix(-5)
#' b2 <- as.matrix(5)
#' c2 <- as.matrix(1)
#' d2 <- as.matrix(0)
#' sysa1 <- ss(a1, b1, c1, d)
#' sysa2 <- ss(a2, b2, c2, d2)
#' al <- append(sysa1, sysa2)
#' connect(al, cbind(2,1,0), cbind(1,2), cbind(1,2))
#' ## OR
#' connect(append(sysa1, sysa2), cbind(2,1,0), cbind(1), cbind(2))
#'  \dontrun{
#' cbind(2,1,0) means that block 2 has an input from block 1 and block 0 (which doesnt exist)
#' cbind(1) means that block 1 is the input of the system, and cbind(2) means block 2 is the
#' output of the system.
#' if we replace cbind(2) with cbind(1,2), this means that the system has two outputs from
#' block 1 and 2
#' i.e. \code{connect(append(sysa1, sysa2), cbind(2,1,0), cbind(1), cbind(1,2))}
#' }
#' @export
connect <- function (sysapp, q, inputs, outputs) {

  if (class(sysapp) != 'ss') {
    sys_ss <- ssdata(sysapp)
  } else {
    sys_ss <- sysapp
  }

  dimQ <- dim(q)
  mq <- dimQ[1]
  nq <- dimQ[2]
  dimD <- dim(sys_ss[[4]])
  md <- dimD[1]
  nd <- dimD[2]

  #pracma::zeros(nd,md)
  k <- matrix(rep(0), nrow <- nd, md)

  for (i in 1:mq){
    qi <- q[i, which(q[i,] != 0, arr.ind = TRUE), drop = FALSE]
    dimQ1 <- dim(qi)
    m <- dimQ1[1]
    n <- dimQ1[2]
    if (n != 1 ){
      k[qi[1], abs(qi[2:n])] <- sign(qi[2:n])
    }
  }

  b_con <- sys_ss[[2]] %*% solve((diag(1, nd) - k * sys_ss[[4]]))
  a_con <- sys_ss[[1]] + b_con %*% k %*% sys_ss[[3]]
  t <- diag(1, md) - sys_ss[[4]] * k
  c_con <- solve(t, sys_ss[[3]])
  d_con <- solve(t, sys_ss[[4]])

  b_con <- b_con[ , inputs, drop = FALSE]
  c_con <- c_con[outputs, , drop = FALSE]
  d_con <- d_con[outputs, inputs, drop = FALSE]

  return(ss(a_con, b_con, c_con, d_con))

}
